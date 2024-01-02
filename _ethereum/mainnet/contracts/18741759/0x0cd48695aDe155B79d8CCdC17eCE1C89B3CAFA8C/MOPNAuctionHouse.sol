// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./console.sol";

import "./IMOPN.sol";
import "./IMOPNBomb.sol";
import "./IMOPNToken.sol";
import "./IMOPNGovernance.sol";
import "./IMOPNLand.sol";

import "./IERC20Receiver.sol";
import "./Multicall.sol";
import "./ABDKMath64x64.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/
contract MOPNAuctionHouse is Multicall {
    IMOPNGovernance public governance;

    event BombSold(address indexed buyer, uint256 amount, uint256 price);

    uint256 public constant landPrice = 1000000000000;

    struct QActStruct {
        uint16[24] qacts;
        uint32 lastQactBlock;
    }

    QActStruct public qact;

    uint32 public landRoundStartBlock;

    uint64 public landRoundId;

    event LandSold(address indexed buyer, uint256 price);

    modifier onlyMOPN() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.auctionHouseContract(),
            "not allowed"
        );
        _;
    }

    constructor(address governance_, uint32 landStartBlock) {
        governance = IMOPNGovernance(governance_);
        landRoundStartBlock = landStartBlock;
        landRoundId = 1;
    }

    /**
     * @notice buy the amount of bombs at current block's price
     * @param amount the amount of bombs
     */
    function buyBomb(uint256 amount) public {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            IMOPNToken(governance.tokenContract()).mopnburn(
                msg.sender,
                price * amount
            );
        }

        _buyBomb(msg.sender, amount, price);
    }

    function buyBombFrom(address from, uint256 amount) public onlyMOPN {
        uint256 price = getBombCurrentPrice();

        if (price > 0) {
            IMOPNToken(governance.tokenContract()).mopnburn(
                from,
                price * amount
            );
        }

        _buyBomb(from, amount, price);
    }

    function _buyBomb(address buyer, uint256 amount, uint256 price) internal {
        increaseQAct(amount);
        IMOPNBomb(governance.bombContract()).mint(buyer, 1, amount);
        emit BombSold(buyer, amount, price);
    }

    function getQActInfo() public view returns (QActStruct memory qact_) {
        qact_ = qact;
    }

    function getQAct() public view returns (uint256 qact_) {
        uint256 qactgap = block.number - qact.lastQactBlock;
        if (qactgap < 7200) {
            uint256 currentIndex = (block.number % 7200) / 300;
            if (qactgap < 300) {
                qact_ = qact.qacts[currentIndex];
            }
            uint256 endIndex = 24 - (qactgap / 300);
            endIndex = (currentIndex + endIndex) % 24;
            currentIndex = (currentIndex + 1) % 24;
            while (currentIndex != endIndex) {
                qact_ += qact.qacts[currentIndex];
                currentIndex = (currentIndex + 1) % 24;
            }
        }
    }

    function increaseQAct(uint256 amount) internal {
        uint256 qactgap = block.number - qact.lastQactBlock;
        uint256 lastIndex = (qact.lastQactBlock % 7200) / 300;
        uint256 currentIndex = (block.number % 7200) / 300;
        uint256 endIndex;
        if (qactgap >= 7200) {
            endIndex = (currentIndex + 1) % 24;
        } else {
            if (lastIndex == currentIndex) {
                if (qactgap >= 300) endIndex = (lastIndex + 1) % 24;
                else endIndex = lastIndex;
            } else {
                endIndex = (lastIndex + 1) % 24;
            }
        }
        while (currentIndex != endIndex) {
            qact.qacts[endIndex] = 0;
            endIndex = (endIndex + 1) % 24;
        }

        qact.lastQactBlock = uint32(block.number);
        if (lastIndex != currentIndex || qactgap >= 300) {
            qact.qacts[currentIndex] = uint16(amount);
        } else {
            if (amount + qact.qacts[currentIndex] > type(uint16).max) {
                qact.qacts[currentIndex] = type(uint16).max;
            } else {
                qact.qacts[currentIndex] += uint16(amount);
            }
        }
    }

    /**
     * @notice get the current auction price by block.timestamp
     * @return price current auction price
     */
    function getBombCurrentPrice() public view returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint256 pmt = mopn.currentMTPPB() * 7200;
        uint256 pexp = (pmt * 7) /
            (91 * IMOPNLand(governance.landContract()).nextTokenId());
        int256 qexp = int256(pmt / (2 * pexp));

        return
            ABDKMath64x64.mulu(
                ABDKMath64x64.exp(
                    ABDKMath64x64.divi(int256(getQAct()) - qexp, qexp)
                ),
                pexp
            );
    }

    /**
     * @notice get current Land Round Id
     * @return roundId round Id
     */
    function getLandRoundId() public view returns (uint64) {
        return landRoundId;
    }

    function getLandRoundStartBlock() public view returns (uint32) {
        return landRoundStartBlock;
    }

    /**
     * @notice buy one land at current block's price
     */
    function buyLand() public {
        uint256 price = getLandCurrentPrice();

        if (price > 0) {
            require(
                IMOPNToken(governance.tokenContract()).balanceOf(msg.sender) >
                    price,
                "MOPNToken not enough"
            );
            IMOPNToken(governance.tokenContract()).mopnburn(msg.sender, price);
        }

        _buyLand(msg.sender, price);
    }

    function _buyLand(address buyer, uint256 price) internal {
        require(block.number >= landRoundStartBlock, "auction not start");

        IMOPNLand(governance.landContract()).auctionMint(buyer, 1);

        emit LandSold(buyer, price);

        landRoundId++;
        landRoundStartBlock = uint32(block.number);
    }

    /**
     * @notice get the current auction price for land
     * @return price current auction price
     */
    function getLandCurrentPrice() public view returns (uint256) {
        if (landRoundStartBlock >= block.number) {
            return landPrice;
        }
        return getLandPrice((block.number - landRoundStartBlock) / 5);
    }

    function getLandPrice(uint256 reduceTimes) public pure returns (uint256) {
        int128 reducePercentage = ABDKMath64x64.divu(99, 100);
        int128 reducePower = ABDKMath64x64.pow(reducePercentage, reduceTimes);
        return ABDKMath64x64.mulu(reducePower, landPrice);
    }

    /**
     * @notice a set of current round data
     * @return roundId round Id of current round
     * @return price
     */
    function getLandCurrentData()
        public
        view
        returns (uint256 roundId, uint256 price, uint256 startTimestamp)
    {
        roundId = getLandRoundId();
        price = getLandCurrentPrice();
        startTimestamp = landRoundStartBlock;
    }

    function onERC20Received(
        address,
        address from,
        uint256 value,
        bytes memory data
    ) public returns (bytes4) {
        require(
            msg.sender == governance.tokenContract(),
            "only accept mopn token"
        );

        if (data.length > 0) {
            (uint256 buyType, uint256 amount) = abi.decode(
                data,
                (uint256, uint256)
            );
            if (buyType == 1) {
                if (amount > 0) {
                    uint256 price = getBombCurrentPrice();
                    _checkTransferInAndRefund(from, value, price * amount);
                    _buyBomb(from, amount, price);
                }
            } else if (buyType == 2) {
                uint256 price = getLandCurrentPrice();
                _checkTransferInAndRefund(from, value, price);
                _buyLand(from, price);
            }
        }

        return IERC20Receiver.onERC20Received.selector;
    }

    function _checkTransferInAndRefund(
        address from,
        uint256 amount,
        uint256 charge
    ) internal {
        if (charge > 0) {
            require(amount >= charge, "mopn token not enough");
            IMOPNToken(governance.tokenContract()).burn(charge);
        }

        if (amount > charge) {
            IMOPNToken(governance.tokenContract()).transfer(
                from,
                amount - charge
            );
        }
    }
}
