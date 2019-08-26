# frozen_string_literal: true

module Api::V1
    # Controller for Instructors
    class InstructorsController < ApplicationController
        # GET /instructors
        def index
            index_response(Instructor, Position, instructors_by_position)
        end

        # GET /session/:id/instructors
        def instructor_by_session
            params.require(:session_id)
            instructors = Instructor.joins(:positions).where(
                positions: { session_id: params[:session_id] }
            )
            render_success(instructors)
        end

        # POST /instructors AND /add_instructor
        def create
            # if we passed in an id that exists, we want to update
            update && return if update_condition(Instructor)
            if params.include?(:position_id)
                position = Position.find(params[:position_id])
                instructor_create(position)
            else
                instructor_create
            end
        end

        def update
            update_entry(Instructor, instructor_params)
        end

        # POST /instructors/delete
        def delete
            delete_entry(Instructor)
        end

        # POST /session/:session_id/instructors/delete
        def delete_instructor_by_session
            # delete an instructor from session is essentially remove
            # the instructor from the all positions of that session
            params.require(:id)
            instructor = Instructor.find(params[:id])
            instructor.positions.each do |position|
                if position.session_id == params[:session_id]
                    position.instructors = position.instructors.except(params[:id])
                    position.save!
                end
            end
            instructor.positions = instructor.positions.except(
                instructor.positions.select { |x| x.session_id == params[:session_id] }
            )
            if instructor.save!
                render_success(instructor)
            else
                render_error(instructor.errors)
            end
        end

        private

        def instructor_params
            params.permit(
                :email,
                :first_name,
                :last_name,
                :utorid
            )
        end

        def instructors_by_position
            Instructor.order(:id).each do |entry|
                entry.position_ids.include?(params[:position_id].to_i)
            end
        end

        def instructor_create(position = false)
            instructor = Instructor.new(instructor_params)
            error = if position
                        instructors_by_position
                    else
                        {}
                    end
            if instructor.save # passes Instructor model validation
                if position
                    position.instructors.push(instructor)
                    render_success(instructors_by_position)
                else
                    render_success(instructor)
                end
            else
                instructor.destroy!
                render_error(instructor.errors.full_messages.join('; '), error)
            end
        end
    end
end
