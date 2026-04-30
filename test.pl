% --- Action Definitions ---
can( move( Block, From, To), [ clear( Block), clear( To), on( Block, From)] ) :-
    is_block( Block),
    object( To),
    To \== Block,
    object( From),
    From \== To,
    Block \== From.

adds( move(X,From,To), [ on(X,To), clear(From)]).
deletes( move(X,From,To), [ on(X,From), clear(To)]).

% --- Domain Definitions ---
is_block(a). is_block(b). is_block(c).
place(1). place(2). place(3). place(4).
object(X) :- place(X) ; is_block(X).

% --- A state in the blocks world ---
state1( [ clear(2), clear(4), clear(b), clear(c), on(a,1), on(b,3), on(c,a) ] ).

% --- The Non-Linear Planner Logic ---
solve( Goals, State, []) :- 
    subset( Goals, State).

solve( Goals, State, Plan) :-
    member( Goal, Goals),
    \+ member( Goal, State),           % Goal not yet met
    adds( Action, AddList),
    member( Goal, AddList),            % Action achieves Goal
    can( Action, Preconditions),
    solve( Preconditions, State, Plan1),
    apply_action( Action, State, NewState),
    solve( Goals, NewState, Plan2),
    append( Plan1, [Action|Plan2], Plan).

apply_action( Action, State, NewState) :-
    deletes( Action, DelList),
    subtract( State, DelList, TempState),
    adds( Action, AddList),
    union( AddList, TempState, NewState).

% --- Utilities ---
subset([], _).
subset([H|T], List) :-
    member(H, List),
    subset(T, List).