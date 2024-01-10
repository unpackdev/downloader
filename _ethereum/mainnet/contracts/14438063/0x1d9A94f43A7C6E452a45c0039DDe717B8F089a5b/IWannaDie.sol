contract IWannaDie {
    function killMe() pure public {
        revert("ERROR: Already dead");
    }
}