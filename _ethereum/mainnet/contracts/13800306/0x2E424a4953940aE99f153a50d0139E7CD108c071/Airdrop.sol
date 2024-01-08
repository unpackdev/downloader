// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract Airdrop is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev address of Radar token holder from which transfer to recipient when claiming tokens
    address immutable public reserveAddress;

    /// @dev address of message signer
    ///      messages need to be signed by this user or claim will be rejected
    address immutable public claimSigner;

    /// @dev address of Radar token
    IERC20 immutable public token;

    /// mapping from recipient to claimed
    mapping(address => bool) public claimed;

    event TokenClaimed(address user, address recipient, uint256 amount);


    /**
     * @dev constructor
     * @param _reserveAddress reserve address
     * @param _claimSigner address of message signer
     * @param _token Radar token address
     */
    constructor(
        address _reserveAddress,
        address _claimSigner,
        address _token
    ) Pausable() Ownable() ReentrancyGuard() {
        require(_reserveAddress != address(0), "RadarAirdrop: invalid reserve address");
        require(_claimSigner != address(0), "RadarAirdrop: invalid claim signer address");
        require(_token != address(0), "RadarAirdrop: invalid token address");

        reserveAddress = _reserveAddress;
        claimSigner = _claimSigner;
        token = IERC20(_token);
    }

    /**
     * @dev claims tokens to recipient based on message signed from ONLY claim signer
     * @param _signature signed message
     * @param _recipient token recepient
     * @param _amount token amount
     */
    function claimTokens(
        bytes calldata _signature,
        address _recipient,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        require(_recipient != address(0), "RadarAirdrop: invalid recipient address");
        require(_amount > 0, "RadarAirdrop: invalid amount");
        require(!claimed[_recipient], "RadarAirdrop: token already claimed to recipient");

        claimed[_recipient] = true;

        bytes32 message = keccak256(abi.encodePacked(_recipient, _amount));

        require(ECDSA.recover(message, _signature) == claimSigner, "RadarAirdrop: invalid signature");

        // transfer token from reserve address to recipient
        token.safeTransferFrom(reserveAddress, _recipient, _amount);

        emit TokenClaimed(msg.sender, _recipient, _amount);
    }

    /**
     * @dev pause contract
     *      only callable by owner
     */
    function pause() external onlyOwner {
        _pause();
    }
}
