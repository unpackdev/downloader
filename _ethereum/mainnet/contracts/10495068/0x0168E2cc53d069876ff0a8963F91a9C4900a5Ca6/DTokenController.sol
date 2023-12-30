pragma solidity 0.5.12;

contract DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
    event OwnerUpdate(address indexed owner, address indexed newOwner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;
    address public newOwner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    // Warning: you should absolutely sure you want to give up authority!!!
    function disableOwnership() public onlyOwner {
        owner = address(0);
        emit OwnerUpdate(msg.sender, owner);
    }

    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != owner, "TransferOwnership: the same owner.");
        newOwner = newOwner_;
    }

    function acceptOwnership() public {
        require(
            msg.sender == newOwner,
            "AcceptOwnership: only new owner do this."
        );
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    ///[snow] guard is Authority who inherit DSAuth.
    function setAuthority(DSAuthority authority_) public onlyOwner {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier onlyOwner {
        require(isOwner(msg.sender), "ds-auth-non-owner");
        _;
    }

    function isOwner(address src) internal view returns (bool) {
        return bool(src == owner);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig)
        internal
        view
        returns (bool)
    {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract DTokenController is DSAuth {
    bool private initialized; // Flags for initializing data

    mapping(address => address) internal dTokens;

    event NewMappingdToken(
        address indexed token,
        address indexed mappingdToken
    );

    constructor() public {
        initialize();
    }

    // --- Init ---
    // This function is used with contract proxy, do not modify this function.
    function initialize() public {
        require(!initialized, "initialize: Already initialized!");
        owner = msg.sender;
        initialized = true;
    }

    /**
     *  @dev Adds new mapping: token => dToken.
     */
    function setdTokensRelation(
        address[] memory _tokens,
        address[] memory _mappingdTokens
    ) public auth {
        require(
            _tokens.length == _mappingdTokens.length,
            "setdTokensRelation: Array length do not match!"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            _setdTokenRelation(_tokens[i], _mappingdTokens[i]);
        }
    }

    function _setdTokenRelation(address _token, address _mappingdToken)
        internal
    {
        require(
            dTokens[_token] == address(0x0),
            "_setdTokenRelation: Has set!"
        );
        dTokens[_token] = _mappingdToken;
        emit NewMappingdToken(_token, _mappingdToken);
    }

    /**
     * @dev Updates existing mapping: token => dToken.
     */
    function updatedTokenRelation(address _token, address _mappingdToken)
        external
        auth
    {
        require(
            dTokens[_token] != address(0x0),
            "updatedTokenRelation: token does not exist!"
        );
        dTokens[_token] = _mappingdToken;
        emit NewMappingdToken(_token, _mappingdToken);
    }

    function getDToken(address _token) external view returns (address) {
        return dTokens[_token];
    }
}