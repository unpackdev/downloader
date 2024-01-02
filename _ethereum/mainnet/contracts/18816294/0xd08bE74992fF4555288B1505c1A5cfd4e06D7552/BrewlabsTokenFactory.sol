// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Clones.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";

contract BrewlabsTokenFactory is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    mapping(uint256 => address) public implementation;
    mapping(uint256 => uint256) public version;

    address public payingToken;
    uint256 public serviceFee;
    address public treasury;

    struct TokenInfo {
        address token;
        uint256 category;
        uint256 version;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address deployer;
        uint256 createdAt;
    }

    TokenInfo[] public tokenInfo;
    mapping(address => bool) public whitelist;

    event StandardTokenCreated(
        address indexed token,
        uint256 category,
        uint256 version,
        string name,
        string symbol,
        uint8 decimals,
        uint256 totalSupply,
        address deployer
    );
    event SetPayingInfo(address token, uint256 price);
    event SetImplementation(uint256 category, address impl, uint256 version);
    event TreasuryChanged(address addr);
    event Whitelisted(address indexed account, bool isWhitelisted);

    constructor() {}

    function initialize(address impl, address token, uint256 price, address locker) external initializer {
        require(impl != address(0x0), "Invalid implementation");

        __Ownable_init();

        payingToken = token;
        serviceFee = price;
        treasury = locker;
        implementation[0] = impl;
        version[0] = 1;

        emit SetImplementation(0, impl, 1);
    }

    function createBrewlabsStandardToken(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply)
        external
        payable
        returns (address token)
    {
        uint256 category = 0;
        require(implementation[category] != address(0x0), "Not initialized yet");

        if (!whitelist[msg.sender]) {
            _transferServiceFee();
        }

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, name, symbol, decimals, block.number, block.timestamp));

        token = Clones.cloneDeterministic(implementation[category], salt);
        (bool success,) = token.call(
            abi.encodeWithSignature(
                "initialize(string,string,uint8,uint256,address)", name, symbol, decimals, totalSupply, msg.sender
            )
        );
        require(success, "Initialization failed");

        tokenInfo.push(
            TokenInfo(
                token, category, version[category], name, symbol, decimals, totalSupply, msg.sender, block.timestamp
            )
        );

        emit StandardTokenCreated(token, category, version[category], name, symbol, decimals, totalSupply, msg.sender);
    }

    function tokenCount() external view returns (uint256) {
        return tokenInfo.length;
    }

    function setImplementation(uint256 category, address impl) external onlyOwner {
        require(isContract(impl), "Invalid implementation");
        implementation[category] = impl;
        version[category] = version[category] + 1;
        emit SetImplementation(category, impl, version[category]);
    }

    function setServiceFee(uint256 fee) external onlyOwner {
        serviceFee = fee;
        emit SetPayingInfo(payingToken, serviceFee);
    }

    function setPayingToken(address token) external onlyOwner {
        payingToken = token;
        emit SetPayingInfo(payingToken, serviceFee);
    }

    function addToWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = true;
        emit Whitelisted(_addr, true);
    }

    function removeFromWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = false;
        emit Whitelisted(_addr, false);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0x0), "Invalid address");

        treasury = newTreasury;
        emit TreasuryChanged(newTreasury);
    }

    /**
     * @notice Emergency withdraw tokens.
     * @param _token: token address
     */
    function rescueTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            uint256 _ethAmount = address(this).balance;
            payable(msg.sender).transfer(_ethAmount);
        } else {
            uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
        }
    }

    function _transferServiceFee() internal {
        if (payingToken == address(0x0)) {
            require(msg.value >= serviceFee, "Not enough fee");
            payable(treasury).transfer(serviceFee);
        } else {
            IERC20(payingToken).safeTransferFrom(msg.sender, treasury, serviceFee);
        }
    }

    // check if address is contract
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    receive() external payable {}
}
