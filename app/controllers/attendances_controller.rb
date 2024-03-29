class AttendancesController < ApplicationController
  
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month,  :update_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
   
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    
    # 出勤時間が未登録であることを判定
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "おつかれさまでした!"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def edit_one_month
  end
  
  
  def update_one_month
    ActiveRecord::Base.transaction do
      attendances_params.each do |id, item|
        # if (item[:started_at].present? && item[:finished_at].blank?)
        #   flash[:danger] = "無効な入力データがあったため、更新をキャンセルしました。"
        #   redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        # end
        attendance = Attendance.find(id)
        attendance.assign_attributes(item)
        if attendance.worked_on == Date.today
          attendance.save!
        else
          attendance.save!(context: :update_working_hours_except_today)
        end
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあったため、更新をキャンセルしました。"
    # redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  
  private
  
  def attendances_params
    params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
  end

  
  
end
