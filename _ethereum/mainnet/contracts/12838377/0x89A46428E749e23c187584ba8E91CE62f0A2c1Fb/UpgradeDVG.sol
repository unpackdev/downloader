// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract UpgradeDVG is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public dvg;
    IERC20 public dvd;
    address public vault;
    address public signer;

    mapping(address => uint256) public swappedAmounts;
    uint256 public totalSwapped;

    event DvgUpgrade(address indexed user, uint256 dvdAmount);
    event DvdAirdrop(address indexed user, uint256 dvdAmount);

    /// @dev Require that the caller must be an EOA account to avoid flash loans
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not EOA");
        _;
    }

    function initialize(address _dvg, address _dvd, address _vault, address _signer) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        dvg = IERC20(_dvg);
        dvd = IERC20(_dvd);
        vault = _vault;
        signer = _signer;
    }

    receive() external payable {
        require(false, "We do not accept the ETH");
    }

    /**
     * @notice Swap the DVG token in the same amount of DVD token.
     * @param _amountToSwap Amount to upgrade
     * @param _allowedAmount Amount allowed to be upgraded
     * @param _signature signature to proof both the sender and the allowed amount
     */
    function upgradeDVG(uint256 _amountToSwap, uint256 _allowedAmount, bytes memory _signature) external onlyEOA nonReentrant returns(uint256 dvdAmount) {
        address sender = _msgSender();
        require(0 < _amountToSwap, "The amountToSwap is invalid");
        require(_amountToSwap <= _allowedAmount, "The amountToSwap must be equal or less than allowedAmount");
        require(isValidSignature(sender, _allowedAmount, _signature), "The specified amount is not allowed for the sender");

        uint256 pending = _allowedAmount.sub(swappedAmounts[sender]);
        require(0 < pending, "Sender already upgraded token for the allowed amount");

        dvdAmount = (_amountToSwap < pending) ? _amountToSwap : pending;

        swappedAmounts[sender] = swappedAmounts[sender].add(dvdAmount);
        totalSwapped = totalSwapped.add(dvdAmount);

        dvg.safeTransferFrom(sender, address(this), dvdAmount);
        dvd.safeTransferFrom(vault, sender, dvdAmount);
        emit DvgUpgrade(sender, dvdAmount);
    }

    /**
     * @notice Airdrop the DVD tokens to the specified addresses.
     * @param _addresses Addresses to airdrop DVD token
     * @param _allowedAmounts Amounts allowed to be upgraded
     * @param _signatures signatures to proof both the senders and the allowed amounts
     */
    function airdropDVD(address[] memory _addresses, uint256[] memory _allowedAmounts, bytes[] memory _signatures) external onlyOwner {
        require(0 < _addresses.length, "No address input");
        require(_addresses.length == _allowedAmounts.length, "Mismatch the parameters");
        require(_addresses.length == _signatures.length, "Mismatch the parameters");

        for (uint i = 0; i < _addresses.length; i ++) {
            address user = _addresses[i];
            uint256 allowedAmount = _allowedAmounts[i];
            bytes memory signature = _signatures[i];
            require(isValidSignature(user, allowedAmount, signature), "The specified amount is not allowed for the user");

            uint256 pending = allowedAmount.sub(swappedAmounts[user]);
            if (0 < pending) {
                swappedAmounts[user] = swappedAmounts[user].add(pending);
                totalSwapped = totalSwapped.add(pending);

                dvd.safeTransferFrom(vault, user, pending);
                emit DvdAirdrop(user, pending);
            }
        }
    }

    function isValidSignature(address _user, uint256 _allowedAmount, bytes memory _signature) internal view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(_user, _allowedAmount));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);

        // check that the signature is from admin signer.
        address recoveredAddress = ECDSA.recover(messageHash, _signature);
        return (recoveredAddress == signer) ? true : false;
    }

    uint256[44] private __gap;
}