import PropTypes from "prop-types";
import {
    FETCH_POSITIONS_SUCCESS,
    FETCH_ONE_POSITION_SUCCESS,
    UPSERT_ONE_POSITION_SUCCESS,
    DELETE_ONE_POSITION_SUCCESS,
    ADD_INSTRUCTOR_TO_POSITION_SUCCESS
} from "../constants";
import { fetchError, upsertError, deleteError } from "./errors";
import {
    actionFactory,
    runOnActiveSessionChange,
    validatedApiDispatcher
} from "./utils";
import { apiGET, apiPOST } from "../../libs/apiUtils";
import { positionsReducer } from "../reducers/positions";
import { createSelector } from "reselect";

window.PT = PropTypes;

// actions
const fetchPositionsSuccess = actionFactory(FETCH_POSITIONS_SUCCESS);
const fetchOnePositionSuccess = actionFactory(FETCH_ONE_POSITION_SUCCESS);
const upsertOnePositionSuccess = actionFactory(UPSERT_ONE_POSITION_SUCCESS);
const deleteOnePositionSuccess = actionFactory(DELETE_ONE_POSITION_SUCCESS);
const addInstructorToPositionSuccess = actionFactory(
    ADD_INSTRUCTOR_TO_POSITION_SUCCESS
);

// dispatchers
export const fetchPositions = validatedApiDispatcher({
    name: "fetchPositions",
    description: "Fetch positions",
    onErrorDispatch: e => fetchError(e.toString()),
    dispatcher: () => async (dispatch, getState) => {
        const { id: activeSessionId } = getState().model.sessions.activeSession;
        const data = await apiGET(`/sessions/${activeSessionId}/positions`);
        dispatch(fetchPositionsSuccess(data));
    }
});

export const fetchPosition = validatedApiDispatcher({
    name: "fetchPosition",
    description: "Fetch position",
    propTypes: { id: PropTypes.any.isRequired },
    onErrorDispatch: e => fetchError(e.toString()),
    dispatcher: payload => async (dispatch, getState) => {
        const { id: activeSessionId } = getState().model.sessions.activeSession;
        const data = await apiGET(
            `/sessions/${activeSessionId}/positions/${payload.id}`
        );
        dispatch(fetchOnePositionSuccess(data));
    }
});

export const upsertPosition = validatedApiDispatcher({
    name: "upsertPosition",
    description: "Add/insert position",
    propTypes: { id: PropTypes.any.isRequired },
    onErrorDispatch: e => upsertError(e.toString()),
    dispatcher: payload => async (dispatch, getState) => {
        const { id: activeSessionId } = getState().model.sessions.activeSession;
        const data = await apiPOST(
            `/sessions/${activeSessionId}/positions`,
            payload
        );
        dispatch(upsertOnePositionSuccess(data));
    }
});

export const deletePosition = validatedApiDispatcher({
    name: "deletePosition",
    description: "Delete position",
    propTypes: { id: PropTypes.any.isRequired },
    onErrorDispatch: e => deleteError(e.toString()),
    dispatcher: payload => async (dispatch, getState) => {
        const { id: activeSessionId } = getState().model.sessions.activeSession;
        const data = await apiPOST(
            `/sessions/${activeSessionId}/positions/delete`,
            payload
        );
        dispatch(deleteOnePositionSuccess(data));
    }
});

export const addInstructorToPosition = validatedApiDispatcher({
    name: "addInstructorToPosition",
    description: "Add instructor to position",
    propTypes: {
        instructor: PropTypes.shape({ id: PropTypes.any.isRequired }),
        position: PropTypes.shape({ id: PropTypes.any.isRequired })
    },
    onErrorDispatch: true,
    dispatcher: payload => async dispatch => {
        const data = await apiPOST(
            `/positions/${payload.position.id}/add_instructor`,
            payload.instructor
        );
        await dispatch(
            addInstructorToPositionSuccess({
                position: payload.position,
                instructors: data
            })
        );
    }
});

// selectors

// Each reducer is given an isolated state; instead of needed to remember to
// pass the isolated state to each selector, `reducer._localStoreSelector` will intelligently
// search for and return the isolated state associated with `reducer`. This is not
// a standard redux function.
export const localStoreSelector = positionsReducer._localStoreSelector;
export const positionsSelector = createSelector(
    localStoreSelector,
    state => state._modelData
);

// Any time the active session changes, we want to refetch
// all data. Calling `runOnActiveSessionChange` ensures that
// when the active session changes all data is re-fetched
runOnActiveSessionChange(fetchPositions);
