// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./console.sol";

import "./IMOPNCollectionVault.sol";
import "./IMOPN.sol";
import "./IMOPNData.sol";
import "./IMOPNToken.sol";
import "./IMOPNGovernance.sol";
import "./IERC20Receiver.sol";
import "./CollectionVaultLib.sol";
import "./ERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Strings.sol";
import "./ABDKMath64x64.sol";

interface ICryptoPunks {
    function buyPunk(uint punkIndex) external;

    function transferPunk(address to, uint punkIndex) external;
}

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/
contract MOPNCollectionVault is
    IMOPNCollectionVault,
    ERC20,
    IERC20Receiver,
    IERC721Receiver
{
    address public immutable governance;

    uint8 public VaultStatus;
    uint32 public AskStartBlock;
    uint64 public AskAcceptPrice;
    uint32 public BidStartBlock;
    uint64 public BidAcceptPrice;
    uint256 public BidAcceptTokenId;

    constructor(address governance_) ERC20("MOPN VToken", "MVT") {
        governance = governance_;
    }

    function name() public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "MOPN VToken #",
                    Strings.toString(
                        IMOPNGovernance(governance).getCollectionVaultIndex(
                            collectionAddress()
                        )
                    )
                )
            );
    }

    function symbol() public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "MVT #",
                    Strings.toString(
                        IMOPNGovernance(governance).getCollectionVaultIndex(
                            collectionAddress()
                        )
                    )
                )
            );
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function collectionAddress() public view returns (address) {
        return CollectionVaultLib.collectionAddress();
    }

    function getCollectionMOPNPoint() public view returns (uint24 point) {
        point = uint24((Math.sqrt(MTBalance() / 100) * 3) / 1000);

        if (AskAcceptPrice > 0) {
            uint24 maxPoint = uint24(
                (Math.sqrt(AskAcceptPrice / 100) * 3) / 100
            );
            if (point > maxPoint) {
                point = maxPoint;
            }
        }
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getAskCurrentPrice() public view returns (uint256 price) {
        if (VaultStatus == 0) return 0;

        price = getAskPrice(block.number - AskStartBlock);
        if (price < 1000000) {
            price = 1000000;
        }
    }

    function getAskPrice(uint256 reduceTimes) public view returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(9995, 10000);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, (BidAcceptPrice * 5) / 4);
    }

    function getAskInfo() public view returns (AskStruct memory auction) {
        auction.vaultStatus = VaultStatus;
        auction.startBlock = AskStartBlock;
        auction.bidAcceptPrice = BidAcceptPrice;
        auction.tokenId = BidAcceptTokenId;
        auction.currentPrice = getAskCurrentPrice();
    }

    function MT2VAmountRealtime(
        uint256 MTAmount,
        bool onReceived
    ) public view returns (uint256 VAmount) {
        if (totalSupply() == 0) {
            VAmount = MTBalanceRealtime();
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                MTBalanceRealtime() -
                (onReceived ? MTAmount : 0);
        }
    }

    function MT2VAmount(
        uint256 MTAmount,
        bool onReceived
    ) public view returns (uint256 VAmount) {
        uint256 balance = IMOPNToken(
            IMOPNGovernance(governance).tokenContract()
        ).balanceOf(address(this));
        if (totalSupply() == 0) {
            VAmount = balance;
        } else {
            VAmount =
                (totalSupply() * MTAmount) /
                (balance - (onReceived ? MTAmount : 0));
        }
    }

    function V2MTAmountRealtime(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = MTBalanceRealtime();
        } else {
            MTAmount = (MTBalanceRealtime() * VAmount) / totalSupply();
        }
    }

    function V2MTAmount(
        uint256 VAmount
    ) public view returns (uint256 MTAmount) {
        if (VAmount == totalSupply()) {
            MTAmount = IMOPNToken(IMOPNGovernance(governance).tokenContract())
                .balanceOf(address(this));
        } else {
            MTAmount =
                (IMOPNToken(IMOPNGovernance(governance).tokenContract())
                    .balanceOf(address(this)) * VAmount) /
                totalSupply();
        }
    }

    function withdraw(uint256 amount) public {
        address collectionAddress_ = CollectionVaultLib.collectionAddress();
        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());
        mopn.claimCollectionMT(collectionAddress_);
        uint256 mtAmount = V2MTAmount(amount);
        require(amount > 0 && mtAmount > 0, "zero to withdraw");
        IMOPNToken(IMOPNGovernance(governance).tokenContract()).transfer(
            msg.sender,
            mtAmount
        );
        _burn(msg.sender, amount);
        mopn.settleCollectionMOPNPoint(
            collectionAddress_,
            getCollectionMOPNPoint()
        );

        emit MTWithdraw(msg.sender, mtAmount, amount);
    }

    function MTBalanceRealtime() public view returns (uint256 amount) {
        amount =
            IMOPNData(IMOPNGovernance(governance).dataContract())
                .calcCollectionSettledMT(
                    CollectionVaultLib.collectionAddress()
                ) +
            IMOPNToken(IMOPNGovernance(governance).tokenContract()).balanceOf(
                address(this)
            );
    }

    function MTBalance() public view returns (uint256 balance) {
        balance = IMOPNToken(IMOPNGovernance(governance).tokenContract())
            .balanceOf(address(this));
    }

    function getBidCurrentPrice() public view returns (uint256) {
        return getBidPrice(block.number - BidStartBlock);
    }

    function getBidPrice(uint256 increaseTimes) public view returns (uint256) {
        uint256 max = MTBalanceRealtime() / 5;
        uint64 AskAcceptPrice_ = (AskAcceptPrice * 3) / 4;
        if (AskAcceptPrice_ == 0 || AskAcceptPrice_ >= max) return max;
        uint256 maxIncreaseTimes = ABDKMath64x64.toUInt(
            ABDKMath64x64.div(
                ABDKMath64x64.ln(
                    ABDKMath64x64.div(
                        ABDKMath64x64.fromUInt(max),
                        ABDKMath64x64.fromUInt(AskAcceptPrice_)
                    )
                ),
                ABDKMath64x64.ln(ABDKMath64x64.div(10005, 10000))
            )
        );
        if (maxIncreaseTimes <= increaseTimes) return max;

        int128 increasePercentage = ABDKMath64x64.divu(10005, 10000);
        int128 increasePower = ABDKMath64x64.pow(
            increasePercentage,
            increaseTimes
        );
        return ABDKMath64x64.mulu(increasePower, AskAcceptPrice_);
    }

    function getBidInfo() public view returns (BidStruct memory bid) {
        bid.vaultStatus = VaultStatus;
        bid.startBlock = BidStartBlock;
        bid.askAcceptPrice = AskAcceptPrice;
        bid.currentPrice = getBidCurrentPrice();
    }

    function acceptBid(uint256 tokenId) public {
        require(VaultStatus == 0, "last ask not finish");
        address collectionAddress_ = CollectionVaultLib.collectionAddress();

        if (collectionAddress_ == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
            ICryptoPunks(collectionAddress_).buyPunk(tokenId);
        } else {
            IERC721(collectionAddress_).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                "0x"
            );
        }

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        mopn.claimCollectionMT(collectionAddress_);

        uint256 offerPrice = getBidCurrentPrice();

        IMOPNToken(IMOPNGovernance(governance).tokenContract()).transfer(
            msg.sender,
            offerPrice
        );

        BidStartBlock = 0;
        BidAcceptTokenId = tokenId;
        BidAcceptPrice = uint64(offerPrice);
        AskStartBlock = uint32(block.number);
        VaultStatus = 1;

        mopn.settleCollectionMOPNPoint(
            collectionAddress_,
            getCollectionMOPNPoint()
        );

        emit BidAccept(msg.sender, tokenId, offerPrice);
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes calldata data
    ) public returns (bytes4) {
        require(
            msg.sender == IMOPNGovernance(governance).tokenContract(),
            "only accept mopn token"
        );

        IMOPN mopn = IMOPN(IMOPNGovernance(governance).mopnContract());

        address collectionAddress_ = CollectionVaultLib.collectionAddress();

        if (bytes32(data) == keccak256("acceptAsk")) {
            require(VaultStatus == 1, "ask not exist");

            require(block.number >= AskStartBlock, "ask not start");

            uint256 price = getAskCurrentPrice();
            require(value >= price, "MOPNToken not enough");

            if (value > price) {
                IMOPNToken(IMOPNGovernance(governance).tokenContract())
                    .transfer(from, value - price);
                value = price;
            }
            uint256 burnAmount;
            if (price > 0) {
                burnAmount = price / 200;
                if (burnAmount > 0) {
                    IMOPNToken(IMOPNGovernance(governance).tokenContract())
                        .burn(burnAmount);

                    price = price - burnAmount;
                }
            }

            mopn.claimCollectionMT(collectionAddress_);
            mopn.settleCollectionMOPNPoint(
                collectionAddress_,
                getCollectionMOPNPoint()
            );

            if (
                collectionAddress_ == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB
            ) {
                ICryptoPunks(collectionAddress_).transferPunk(
                    from,
                    BidAcceptTokenId
                );
            } else {
                IERC721(collectionAddress_).safeTransferFrom(
                    address(this),
                    from,
                    BidAcceptTokenId,
                    "0x"
                );
            }

            emit AskAccept(from, BidAcceptTokenId, price + burnAmount);

            VaultStatus = 0;
            AskStartBlock = 0;
            AskAcceptPrice = uint64(price + burnAmount);
            BidStartBlock = uint32(block.number);
            BidAcceptPrice = 0;
            BidAcceptTokenId = 0;
        } else {
            require(VaultStatus == 0, "no staking during ask");
            mopn.claimCollectionMT(collectionAddress_);

            uint256 vtokenAmount = MT2VAmount(value, true);
            require(vtokenAmount > 0, "need more mt to get at least 1 vtoken");
            _mint(from, vtokenAmount);
            mopn.settleCollectionMOPNPoint(
                collectionAddress_,
                getCollectionMOPNPoint()
            );

            emit MTDeposit(from, value, vtokenAmount);
        }

        return IERC20Receiver.onERC20Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
