pragma solidity ^0.6.0;

abstract contract Authorizable {
    modifier auth(address _user) {
        require(_isUserAuthorized(_user), "!auth");
        _;
    }

    function _isUserAuthorized(address _user)
        internal
        view
        virtual
        returns (bool);
}
