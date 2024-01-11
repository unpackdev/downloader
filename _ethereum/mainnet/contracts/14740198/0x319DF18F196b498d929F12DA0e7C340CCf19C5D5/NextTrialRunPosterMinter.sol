// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./draft-EIP712.sol";

interface NextTrialRunPoster {
    function mint(address,uint256) external;
}

contract NextTrialRunPosterMinter is EIP712, Ownable {

    NextTrialRunPoster public constant nextTrialRunPoster =
        NextTrialRunPoster(0x339Cac7E7719D701A251930Ebe5eA10E37A2Fd0a);

    /**
        EIP712
     */
    bytes32 public constant GIVEAWAY_TYPEHASH =
        keccak256("SignGiveaway(address receiver,uint256 maxAmount)");
    struct SignGiveaway {
        address receiver;
        uint256 maxAmount;
    }

    /**
        Max supply
     */
     uint256 public constant MAX_SUPPLY = 2692;

    /**
        Pause mint
    */
    bool public mintPaused = false;

    /**
        Giveaway Mints
     */    
    // minted through giveaways
    uint256 public numGiveaways = 0;
    // max giveaways
    mapping(address => uint256) public giveawaysOf;
    
    /**
        Scheduling
     */
    uint256 public giveawayOpeningHours = 1652270400; // Wednesday, May 11, 2022 8:00:00 PM GMT+08:00
    uint256 public constant operationSeconds = 3600 * 24 * 4; // 4 days


    event SetGiveawayOpeningHours(uint256 giveawayOpeningHours);
    event MintGiveaway(address account, uint256 amount);
    event MintPaused(bool mintPaused);

    constructor() EIP712("NextTrialRunPosterMinter", "1") {}

    modifier whenNotPaused() {
        require(
            !mintPaused,
            "Store is closed"
        );
        _;
    }

    modifier whenGiveawayOpened() {
        require(
            block.timestamp >= giveawayOpeningHours,
            "Store is not opened for giveaway mints"
        );
        require(
            block.timestamp < giveawayOpeningHours + operationSeconds,
            "Store is closed for giveaway mints"
        );
        _;
    }

    function setMintPaused(bool _mintPaused) external onlyOwner{
        mintPaused = _mintPaused;
        emit MintPaused(_mintPaused);
    }

    function setGiveawayOpeningHours(uint256 _giveawayOpeningHours) external onlyOwner {
        giveawayOpeningHours = _giveawayOpeningHours;
        emit SetGiveawayOpeningHours(_giveawayOpeningHours);
    }


    function mintByGiveaway(
        uint256 _nftAmount,
        uint256 _maxAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external whenNotPaused whenGiveawayOpened {
        uint256 myGiveaways = giveawaysOf[msg.sender];
        require(myGiveaways == 0, "Tsk tsk, not too greedy please");

        require(numGiveaways + _nftAmount <= MAX_SUPPLY, "Max number of giveaways reached");

        require(_nftAmount <= _maxAmount, "Mint amount exceeds allocated amount");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(GIVEAWAY_TYPEHASH, msg.sender, _maxAmount))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        giveawaysOf[msg.sender] = _nftAmount; //update who has claimed their giveaways

        nextTrialRunPoster.mint(msg.sender, _nftAmount);

        numGiveaways += _nftAmount;

        emit MintGiveaway(msg.sender, _nftAmount);
    }

    fallback () external payable {
       revert(); // Reject any Ether transfer
    }

    receive () external payable {
        revert(); //Reject any Ether transfer
    }

} 