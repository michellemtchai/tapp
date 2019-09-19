# frozen_string_literal: true

module Api::V1
    # Controller for Sessions
    class SessionsController < ApplicationController
        # GET /sessions
        def index
            render_success(Session.order(:id))
        end

        # POST /sessions
        def create
            # if we passed in an id that exists, we want to update
            update && return if should_update(Session, params)
            params.require(:name)
            create_entry(Session, session_params)
        end

        def update
            entry = Session.find(params[:id])
            update_entry(entry, session_params)
        end

        # POST /sessions/delete
        def delete
            delete_entry(Session, params)
        end

        private

        def session_params
            params.permit(
                :id,
                :name,
                :rate1,
                :rate2,
                :start_date,
                :end_date
            )
        end
    end
end
