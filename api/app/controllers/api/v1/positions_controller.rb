# frozen_string_literal: true

module Api::V1
    # Controller for Positions
    class PositionsController < ApplicationController
        # GET /positions
        def index
            index_response(all_positions, Session, positions_by_session, true)
        end

        # POST /positions
        def create
            # if we passed in an id that exists, we want to update
            update && return if should_update(Position, params)
            return if invalid_id_check(Session)

            params.require(%i[position_code position_title])
            create_subparts = proc do |position|
                update_instructors_ids(position)
                params[:position_id] = position[:id]
                message = valid_ad_and_matching(position.errors.messages)
                if !message
                    render_success(position_data(position))
                else
                    position.destroy!
                    render_error(message)
                end
            end
            create_entry(Position, position_params, after_fn: create_subparts)
        end

        def update
            parts_fn = proc do |position|
                ad = position.position_data_for_ad
                matching = position.position_data_for_matching
                update_instructors_ids(position)

                ad_res = ad.update_attributes!(ad_update_params)
                matching_res = matching.update_attributes!(matching_update_params)

                errors = position.errors.messages.deep_merge(ad.errors.messages)
                errors = errors.deep_merge(matching.errors.messages)
                [ad_res && matching_res, errors]
            end
            merge_fn = proc { |i| position_data(i) }
            entry = Position.find(params[:id])
            update_entry(entry, position_update_params,
                         parts_fn: parts_fn, merge_fn: merge_fn)
        end

        # POST /positions/delete
        def delete
            delete_matching_and_ad = proc do |position|
                matching = position.position_data_for_matching
                ad = position.position_data_for_ad
                matching.destroy!
                ad.destroy!
            end
            delete_entry(Position, params, delete_matching_and_ad)
        end

        private

        # Only allow a trusted parameter "white position" through.
        def position_params
            params.permit(
                :session_id,
                :position_code,
                :position_title,
                :est_hours_per_assignment,
                :est_start_date,
                :est_end_date,
                :position_type
            )
        end

        def position_data_for_ad_params
            params.permit(
                :position_id,
                :duties,
                :qualifications,
                :ad_hours_per_assignment,
                :ad_num_assignments,
                :ad_open_date,
                :ad_close_date
            )
        end

        def position_data_for_matching_params
            params.permit(
                :position_id,
                :desired_num_assignments,
                :current_enrollment,
                :current_waitlisted
            )
        end

        def position_update_params
            params.permit(
                :position_code,
                :position_title,
                :est_hours_per_assignment,
                :est_start_date,
                :est_end_date,
                :position_type
            )
        end

        def ad_update_params
            params.permit(
                :duties,
                :qualifications,
                :ad_hours_per_assignment,
                :ad_num_assignments,
                :ad_open_date,
                :ad_close_date
            )
        end

        def matching_update_params
            params.permit(
                :desired_num_assignments,
                :current_enrollment,
                :current_waitlisted
            )
        end

        def positions_by_session
            filter_given_id(all_positions, :session_id, true)
        end

        def all_positions
            Position.order(:id).map do |entry|
                position_data(entry)
            end
        end

        def position_data(position)
            exclusion = %i[id created_at updated_at position_id]
            matching = position.position_data_for_matching
            matching = json(matching, except: exclusion)
            ad = position.position_data_for_ad
            combined = json(ad, include: matching, except: exclusion)
            combined = json(combined, include: { instructor_ids: position.instructor_ids })
            json(position, include: combined)
        end

        def update_instructors_ids(position)
            if params.include?(:instructor_ids)
                return if params[:instructor_ids] == ['']

                params[:instructor_ids].each do |id|
                    Instructor.find(id)
                end
                position.instructor_ids = params[:instructor_ids]
            end
        end

        def valid_ad_and_matching(errors)
            ad = PositionDataForAd.new(position_data_for_ad_params)
            matching = PositionDataForMatching.new(position_data_for_matching_params)
            ad_save = ad.save
            matching_save = matching.save
            if ad_save && matching_save
                return nil
            elsif ad_save && !matching_save
                ad.destroy!
                matching.destroy!
                return errors.deep_merge(matching.errors.messages)
            elsif !ad_save && matching_save
                ad.destroy!
                matching.destroy!
                return errors.deep_merge(ad.errors.messages)
            else
                ad.destroy!
                matching.destroy!
                errors = errors.deep_merge(ad.errors.messages)
                return errors.deep_merge(matching.errors.messages)
            end
        end
    end
end
