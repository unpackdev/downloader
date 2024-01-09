//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./ERC721A.sol";

//////////////////////////////////////////////////////
//                                                  //
// We are Rebirth Lab.                              //
// Let us help you with your next NFT Project.      //
// jeffreylin0723@gmail.com                         //
//                                                  //
//////////////////////////////////////////////////////

/**
 @title SharkDooDoo NFT 
 @author Justa Liang
 */
contract SharkDooDoo is ERC721A, Ownable, EIP712 {
    using Address for address;

    // Stage info (packed)
    struct StageInfo {
        uint8 stageId;
        uint16 maxSupply;
        uint32 startTime;
        uint32 endTime;
        uint160 mintPrice;
    }
    StageInfo public stageInfo;

    // Maximum limit of tokens that can ever exist
    uint16 private constant MAX_SUPPLY = 6999;

    // Stage ID at public stage
    uint8 private constant PUBLIC_STAGE_ID = 2;

    // The base link that leads to the image / video of the token
    string private _baseTokenURI;

    struct MinterInfo {
        uint8 stageId;
        uint8 remain;
    }
    // Stage ID check
    mapping(address => MinterInfo) private _whitelistInfo;

    // voucher for user to redeem
    struct NFTVoucher {
        address redeemer; // specify user to redeem this voucher
        uint8 stageId; // ID to check if voucher has been redeemed
        uint8 amount; // max amount to mint in stage
    }

    /// @dev Setup ERC721A, EIP712 and first stage info
    constructor(StageInfo memory _initStageInfo, string memory _initBaseURI)
        ERC721A("SharkDooDoo", "SHDD", 10)
        EIP712("SharkDooDoo", "1")
    {
        _baseTokenURI = _initBaseURI;
        stageInfo = _initStageInfo;
    }

    /// @notice Whitelist mint using the voucher
    function whitelistMint(
        NFTVoucher calldata voucher,
        bytes calldata signature,
        uint8 amount
    ) external payable {
        MinterInfo storage minterInfo = _whitelistInfo[_msgSender()];
        // if haven't redeemed then redeem first
        if (minterInfo.stageId < stageInfo.stageId) {
            // make sure that the signer is authorized to mint NFTs
            _verify(voucher, signature);
            // check current stage
            require(voucher.stageId == stageInfo.stageId, "Wrong stage");
            // update minter info
            minterInfo.stageId = voucher.stageId;
            minterInfo.remain = voucher.amount;
        }

        // check time
        require(block.timestamp >= stageInfo.startTime, "Sale not started");
        require(block.timestamp <= stageInfo.endTime, "Sale already ended");
        // check if enough remain
        require(amount <= minterInfo.remain, "Not enough remain");
        // check if exceed
        require(
            totalSupply() + amount <= stageInfo.maxSupply,
            "Exceed stage max supply"
        );
        // check fund
        require(msg.value >= stageInfo.mintPrice * amount, "Not enough fund");
        super._safeMint(_msgSender(), amount);
        minterInfo.remain -= amount;
    }

    /// @notice Public mint
    function publicMint(uint8 amount) external payable {
        // check public mint stage
        require(
            stageInfo.stageId == PUBLIC_STAGE_ID,
            "Public mint not started"
        );
        // check time
        require(block.timestamp >= stageInfo.startTime, "Sale not started");
        require(block.timestamp <= stageInfo.endTime, "Sale already ended");
        // check if exceed total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed total supply");
        // check fund
        require(msg.value >= stageInfo.mintPrice * amount, "Not enough fund");
        // batch mint
        super._safeMint(_msgSender(), amount);
    }

    /// @dev Verify voucher
    function _verify(NFTVoucher calldata voucher, bytes calldata signature)
        private
        view
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFTVoucher(address redeemer,uint8 stageId,uint8 amount)"
                    ),
                    _msgSender(),
                    voucher.stageId,
                    voucher.amount
                )
            )
        );
        require(
            owner() == ECDSA.recover(digest, signature),
            "invalid or unauthorized"
        );
    }

    /// @dev Reserve NFT
    function reserve(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed total supply");
        super._safeMint(to, amount);
    }

    /// @dev Go to next stage
    function nextStage(StageInfo memory _stageInfo) external onlyOwner {
        require(
            _stageInfo.stageId >= stageInfo.stageId,
            "Cannot set to previous stage"
        );
        require(_stageInfo.maxSupply <= MAX_SUPPLY, "Set exceed max supply");
        require(_stageInfo.stageId <= PUBLIC_STAGE_ID, "Public is final stage");
        stageInfo = _stageInfo;
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @dev Withdraw
    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /// @dev override _baseURI()
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
