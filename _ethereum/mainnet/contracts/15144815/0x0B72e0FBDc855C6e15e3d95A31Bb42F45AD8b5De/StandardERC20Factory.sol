//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;

import "./IStandardERC20.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

contract StandardERC20Factory is Ownable {
    using Clones for address;
    using SafeERC20 for IERC20Metadata;

    struct DistributionParam {
        address recipient;
        uint256 amount;
        uint256 lockDate;
    }

    struct Reserve {
        address token;
        uint256 amount;
        uint256 lockDate;
    }

    struct Token {
        string symbol;
        uint8 decimal;
        address addr;
        string logoURL;
    }

    struct Tokens {
        Token[] list;
        uint256 size;
    }

    address public tokenImpl;
    mapping(address => string) public logoURLs;
    mapping(address => Reserve[]) public reserves;
    mapping(address => address[]) public tokensByAccount;

    event CreateERC20(address indexed creator, address token);
    event ClaimReserve(address indexed account, address indexed token, uint256 amount);

    constructor(address tokenImpl_) {
        tokenImpl = tokenImpl_;
    }

    /** ---------- admin ---------- **/
    function setTokenImpl(address tokenImpl_) onlyOwner external {
        tokenImpl = tokenImpl_;
    }

    /** ---------- public ---------- **/
    function createERC20(
        string memory name_,
        string memory symbol_,
        string memory logoUrl_,
        uint8 decimal_,
        uint256 totalSupply_,
        DistributionParam[] calldata distributions_
    ) external {
        address _token = tokenImpl.clone();
        IStandardERC20(_token).initialize(name_, symbol_, decimal_, totalSupply_);
        logoURLs[_token] = logoUrl_;
        tokensByAccount[msg.sender].push(_token);

        // distribute
        uint256 _distributedAmount = 0;
        for (uint256 index = 0; index < distributions_.length; index++) {
            DistributionParam calldata _distribution = distributions_[index];
            reserves[_distribution.recipient].push(Reserve({
                token: _token,
                amount: _distribution.amount,
                lockDate: _distribution.lockDate
            }));
            _distributedAmount += _distribution.amount;
        }
        if (totalSupply_ > _distributedAmount)
            IERC20Metadata(_token).safeTransfer(msg.sender, totalSupply_ - _distributedAmount);
        else
            require(totalSupply_ == _distributedAmount, 'StandardERC20Factory: distributed amount exceed totalSupply');

        emit CreateERC20(msg.sender, _token);
    }

    function claimReserve(address token_) external {
        Reserve[] memory _reserves = reserves[msg.sender];
        for (uint256 index = 0; index < _reserves.length; index++) {
            Reserve memory _reserve = _reserves[index];
            if (_reserve.token == token_) {
                require(block.timestamp >= _reserve.lockDate, 'StandardERC20Factory: lock');
                if (index < _reserves.length - 1)
                    reserves[msg.sender][index] = reserves[msg.sender][_reserves.length - 1];
                reserves[msg.sender].pop();

                IERC20Metadata(token_).safeTransfer(msg.sender, _reserve.amount);
                emit ClaimReserve(msg.sender, token_, _reserve.amount);
                break;
            }
        }
    }

    /** ---------- public getting ---------- **/
    function getReserved(address account_) view public returns (Reserve[] memory) {
        return reserves[account_];
    }

    function getTokens(address account_, uint256 count_, uint256 offset_) view public returns(Tokens memory) {
        Tokens memory _result;

        address[] memory _addresses = tokensByAccount[account_];
        _result.size = _addresses.length;
        uint256 _limit = count_ + offset_;
        if (_limit > _result.size) _limit = _result.size;

        _result.list = new Token[](_limit > offset_ ? _limit - offset_ : 0);
        for (uint256 _index = offset_; _index < _limit; _index++) {
            _result.list[_index - offset_] = Token({
                symbol: IERC20Metadata(_addresses[_index]).symbol(),
                decimal: IERC20Metadata(_addresses[_index]).decimals(),
                addr: _addresses[_index],
                logoURL: logoURLs[_addresses[_index]]
            });
        }

        return _result;
    }

}