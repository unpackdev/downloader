pragma solidity ^0.7.0;

import "./AccessControl.sol";
import "./Clones.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IBridge.sol";
import "./IBridgedStandardERC20.sol";

contract Bridge is AccessControl, IBridge {

    using Clones for address;
    using SafeERC20 for IERC20;

    struct Pair {
        address tokenAtStart;
        address tokenAtEnd;
    }

    bytes32 public constant BOT_MESSANGER_ROLE = keccak256("BOT_MESSANGER_ROLE");

    bool public direction; // true - on eth, false - on fantom
    IBridgedStandardERC20 public bridgedStandardERC20;

    Pair[] private tokenPairs;

    // token => is allowed to bridge
    mapping(address => bool) public allowedTokens;

    modifier onlyAtStart {
        require(direction, "onlyAtStart");
        _;
    }

    modifier onlyAtEnd {
        require(!direction, "onlyAtEnd");
        _;
    }

    modifier onlyMessangerBot {
        require(hasRole(BOT_MESSANGER_ROLE, _msgSender()), "onlyMessangerBot");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");
        _;
    }

    modifier tokenIsAllowed(address _token) {
        require(allowedTokens[_token], "invalidToken");
        _;
    }

    constructor(
        bool _direction,
        address _bridgedStandardERC20,
        address _botMessanger,
        address _allowedToken,
        string memory _name,
        string memory _symbol
    ) {
        direction = _direction;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BOT_MESSANGER_ROLE, _botMessanger);

        if (_bridgedStandardERC20 != address(0)) {
            bridgedStandardERC20 = IBridgedStandardERC20(_bridgedStandardERC20);
        }

        if (_direction) {
            allowedTokens[_allowedToken] = true;
        } else {
            _cloneAndInitializeTokenAtEndForTokenAtStart(_allowedToken, _name, _symbol);
        }
    }

    function setBridgedStandardERC20(IBridgedStandardERC20 _bridgedStandardERC20) external onlyAdmin {
        bridgedStandardERC20 = _bridgedStandardERC20;
    }

    function evacuateTokens(address _token, uint256 _amount, address _to) external onlyAdmin {
        require(!allowedTokens[_token], "cannotEvacuateAllowedToken");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function setAllowedToken(address _token, bool _status) external onlyAdmin {
        allowedTokens[_token] = _status;
    }

    function requestBridgingToEnd(
        address _tokenAtStart,
        address _to,
        uint256 _amount
    ) external override onlyAtStart tokenIsAllowed(_tokenAtStart) {
        address sender = _msgSender();
        IERC20(_tokenAtStart).safeTransferFrom(sender, address(this), _amount);
        emit RequestBridgingToEnd(_tokenAtStart, sender, _to, _amount);
    }

    function requestBridgingToStart(
        address _tokenAtStart,
        address _tokenAtEnd,
        address _to,
        uint256 _amount
    ) external override onlyAtEnd tokenIsAllowed(_tokenAtEnd) {
        address sender = _msgSender();
        IBridgedStandardERC20(_tokenAtEnd).burn(sender, _amount);
        emit RequestBridgingToStart(_tokenAtStart, _tokenAtEnd, sender, _to, _amount);
    }

    function performBridgingToEnd(
        address _tokenAtStart,
        address _to,
        uint256 _amount,
        string memory _name,
        string memory _symbol
    )
        external
        override
        onlyAtEnd
        onlyMessangerBot
    {
        address tokenAtEnd = getEndTokenByStartToken(_tokenAtStart);
        if (tokenAtEnd == address(0)) {
            tokenAtEnd = _cloneAndInitializeTokenAtEndForTokenAtStart(
                _tokenAtStart,
                _name,
                _symbol
            );
        }
        IBridgedStandardERC20(tokenAtEnd).mint(_to, _amount);
        emit BridgingToEndPerformed(_tokenAtStart, tokenAtEnd, _to, _amount);
    }

    function performBridgingToStart(
        address _tokenAtStart,
        address _tokenAtEnd,
        address _to,
        uint256 _amount
    )
        external
        override
        onlyAtStart
        onlyMessangerBot
    {
        IERC20(_tokenAtStart).safeTransfer(_to, _amount);
        emit BridgingToStartPerformed(_tokenAtEnd, _tokenAtStart, _to, _amount);
    }

    function _cloneAndInitializeTokenAtEndForTokenAtStart(
        address _tokenAtStart,
        string memory _name,
        string memory _symbol
    )
        internal
        returns(address tokenAtEnd)
    {
        tokenAtEnd = address(bridgedStandardERC20).clone();
        tokenPairs.push(Pair({
          tokenAtStart: _tokenAtStart,
          tokenAtEnd: tokenAtEnd
        }));
        allowedTokens[tokenAtEnd] = true;
        IBridgedStandardERC20(tokenAtEnd).configure(
            address(this),
            _tokenAtStart,
            _name,
            _symbol
        );
    }

    function getEndTokenByStartToken(address _startToken) public view returns(address) {
        for (uint i = 0; i < tokenPairs.length; i++) {
            if (tokenPairs[i].tokenAtStart == _startToken) {
                return tokenPairs[i].tokenAtEnd;
            }
        }
        return address(0);
    }

    function getStartTokenByEndToken(address _endToken) external view returns(address) {
        for (uint i = 0; i < tokenPairs.length; i++) {
            if (tokenPairs[i].tokenAtEnd == _endToken) {
                return tokenPairs[i].tokenAtStart;
            }
        }
        revert('noStartTokenFound');
    }

}
