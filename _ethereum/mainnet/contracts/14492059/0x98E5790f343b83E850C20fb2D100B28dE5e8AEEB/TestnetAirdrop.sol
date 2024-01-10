pragma solidity 0.8.13;

/***
 *@title TestnetAirdrop
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice modified from https://github.com/Uniswap/merkle-distributor
 */

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IInsureDepositor.sol";
import "./IOwnership.sol";

contract TestnetAirdrop {
    using SafeERC20 for IERC20;

    event Claimed(uint256 index, address account, uint256 amount, uint256 tax);
    event Locked(uint256 index, address account, uint256 amount);

    address public immutable token;
    bytes32 public immutable merkleRoot;

    uint256 public constant START = 1648684800; //2022-03-31 00:00:00 UTC
    uint256 public constant TAX_PERIOD = 86400 * 365 / 4;
    uint256 public constant CLAIM_DURATION = 86400 * 365 / 2;

    uint256 public constant INIT_RATE = 500000; //50%
    uint256 public constant DENOMINATOR = 1000000; //100%
    uint256 public taxPool;

    address public immutable vlinsure;
    IOwnership public immutable ownership;

    mapping(uint256 => uint256) private claimedBitMap;

    modifier onlyOwner() {
        require(
            ownership.owner() == msg.sender,
            "Caller is not allowed to operate"
        );
        _;
    }

    constructor(address token_, bytes32 merkleRoot_, address vlinsure_, address ownership_){
        require(token_ != address(0), "zero address");
        require(merkleRoot_ != bytes32(0), "zero bytes");
        require(vlinsure_ != address(0), "zero address");
        require(ownership_ != address(0), "zero address");

        token = token_;
        merkleRoot = merkleRoot_;
        vlinsure = vlinsure_;
        ownership = IOwnership(ownership_);

        IERC20(token).safeApprove(vlinsure_, type(uint256).max);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _checkin(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)private {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));

        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        /**
        *@notice claim INSURE with tax dedaction.
        * tax rate decreases from 50% to 0% within 3months linearly
        *@param index markle data to be used to verify
        *@param amount markle data to be used to verify
        *@param merkleProof markle data to be used to verify
        */

        //check merkle
        _checkin(index, msg.sender, amount, merkleProof);

        //check time
        uint256 _time = block.timestamp;
        uint256 END = START + TAX_PERIOD;
        require(_time > START, "TOO EARLY");
        require(_time < START + CLAIM_DURATION, "TOO LATE");

        //calc tax
        uint256 _tax;
        if(_time < END){
            unchecked{
                uint256 _rate = INIT_RATE * (END - _time) / (TAX_PERIOD);

                _tax = amount * _rate / DENOMINATOR;

                amount -= _tax;
                taxPool += _tax;
            }
        }

        //airdrop
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Claimed(index, msg.sender, amount, _tax);
    }

    function lock(uint256 index, uint256 amount, bytes32[] calldata merkleProof)external{
        /**
        *@notice claim vlINSURE without taxation
        *@param index markle data to be used to verify
        *@param amount markle data to be used to verify
        *@param merkleProof markle data to be used to verify
        */

        //check merkle
        _checkin(index, msg.sender, amount, merkleProof);

        //check time
        uint256 _time = block.timestamp;
        require(_time > START, "TOO EARLY");
        require(_time < START + CLAIM_DURATION, "TOO LATE");

        //lock and airdrop
        IInsureDepositor(vlinsure).deposit(amount, false, false);
        uint256 _amount = IERC20(vlinsure).balanceOf(address(this));
        IERC20(vlinsure).safeTransfer(msg.sender, _amount);

        emit Locked(index, msg.sender, amount);
    }

    function salvage() external onlyOwner{
        /**
        *@notice owner can rug-pull the unclaimed airdrop and pooled tax
        *@dev transfer to the community treasure at the end.
        */

        require(block.timestamp > START + CLAIM_DURATION, "Still in Claimable Period");

        uint256 _amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, _amount);
    }
}