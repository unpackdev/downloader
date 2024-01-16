//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Strings.sol";
import "./AbstractERC1155Factory.sol";

/*
 * @title ERC1155 token for NFT 2048
 * @author WayneHong @ Norika
 */
contract NFT2048 is AbstractERC1155Factory {
    using Strings for uint256;

    uint256 public constant LEVEL_0_COUNT = 12_288;
    uint256 public constant MINT_PRICE = 0.009 ether;
    uint256 public constant MAX_LEVEL = 12;
    uint128 public constant MAX_MINT_LIMIT = 8;

    uint256 public constant PRIZE_PERCENTAGE = 40;
    uint256 public constant PRIZE_4096 = 0.2 ether;

    uint256 private first2048creationTimestamp = 0;

    mapping(address => uint256) public token4096HoldAt;
    uint256 public token4096RedeemCount = 0;
    uint256 public level0MintCount = 0;

    uint256 public constant MAX_RANING_SIZE = 5;
    address[] public rankingAddresses;
    mapping(address => uint256) public rankingAddressIndexMapping;

    struct UserMintData {
        uint64 mintCount;
        uint64 totalCount;
        uint128 totalPoint;
        uint256 lastMintBlock;
    }
    mapping(address => UserMintData) public userMintDataMapping;

    struct RoundPrizeData {
        uint256 roundPrize;
        uint256 redeemCount;
        mapping(address => bool) isRedeemed;
    }
    mapping(uint256 => RoundPrizeData) public roundPrizeMapping;

    constructor()
        ERC1155("ipfs://QmQYEAWzP9wLk5bgArm7nbq11fzT9VanKDX9kb7UV6qHzp/")
    {
        name_ = "NFT 2048";
        symbol_ = "2048";
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    function mint(uint64 quantity) external payable callerIsUser {
        require(
            level0MintCount + quantity <= LEVEL_0_COUNT,
            "Exceed total supply"
        );

        UserMintData storage mintData = userMintDataMapping[msg.sender];
        require(
            mintData.lastMintBlock < block.number,
            "Exceed time limit, please wait"
        );
        mintData.lastMintBlock = block.number;

        require(
            mintData.mintCount + quantity <= MAX_MINT_LIMIT,
            "Exceed mint limit"
        );

        uint256 currentMintPrice = mintData.mintCount + quantity > 2
            ? MINT_PRICE
            : 0;
        require(msg.value >= currentMintPrice, "Ether is not enough");

        mintData.mintCount = mintData.mintCount + quantity;
        _mint(msg.sender, 0, quantity, "");
    }

    function isAbleToCombineTokens(address addr) external view returns (bool) {
        uint128 totalPoint = userMintDataMapping[addr].totalPoint;

        for (uint256 i = 0; i <= MAX_LEVEL; i++) {
            if (totalPoint < getTokenPoint(i)) {
                break;
            }

            uint256 levelBalance = balanceOf(addr, i);
            if (levelBalance > 1 && i != MAX_LEVEL) {
                return true;
            }
        }
        return false;
    }

    function combineAllTokens() external callerIsUser {
        uint128 totalPoint = userMintDataMapping[msg.sender].totalPoint;
        uint64 newCount = 0;

        for (uint256 i = 0; i <= MAX_LEVEL; i++) {
            if (totalPoint < getTokenPoint(i)) {
                break;
            }

            uint256 levelExists = totalPoint & (1 << i);
            uint256 levelBalance = balanceOf(msg.sender, i);

            if (levelExists > 0) {
                uint256 afterCombineCount = levelExists / getTokenPoint(i);
                newCount += uint64(afterCombineCount);

                if (afterCombineCount > levelBalance) {
                    _mint(msg.sender, i, afterCombineCount - levelBalance, "");
                    if (i == MAX_LEVEL && token4096HoldAt[msg.sender] == 0) {
                        token4096HoldAt[msg.sender] = block.timestamp;
                    }
                } else if (levelBalance > afterCombineCount) {
                    _burn(msg.sender, i, levelBalance - afterCombineCount);
                }
            } else if (levelExists == 0 && levelBalance > 0) {
                _burn(msg.sender, i, levelBalance);
            }
        }

        userMintDataMapping[msg.sender].totalCount = newCount;
    }

    //  Owner of 4096 for over 1 week can redeem 4096 prize
    function redeem4096Prize() external callerIsUser {
        require(token4096HoldAt[msg.sender] > 0, "4096 token not found");
        require(token4096RedeemCount < 3, "No prize left");
        require(
            block.timestamp - token4096HoldAt[msg.sender] >= 604800,
            "Hold less than 1 week"
        );
        require(address(this).balance >= PRIZE_4096, "Prize no enough");

        token4096RedeemCount += 1;
        token4096HoldAt[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: PRIZE_4096}("");
        require(success, "Transfer failed.");
    }

    // We have a rank for the best 5 owners, which can redeem 40% fee as prize after 2048 is minted
    function redeemRankPrize() external callerIsUser {
        require(rankingAddressIndexMapping[msg.sender] > 0, "Not in rank list");
        require(
            userMintDataMapping[msg.sender].totalPoint > 0,
            "No token found"
        );

        require(first2048creationTimestamp > 0, "Redeem time is not started");
        uint256 roundIndex = (block.timestamp - first2048creationTimestamp) /
            1209600;

        RoundPrizeData storage roundData = roundPrizeMapping[roundIndex];
        require(roundData.isRedeemed[msg.sender] == false, "Has redeemed");
        require(
            roundData.redeemCount < rankingAddresses.length,
            "Reach redeem limit"
        );

        if (roundData.roundPrize == 0) {
            roundData.roundPrize =
                (address(this).balance * PRIZE_PERCENTAGE) /
                100;
        }
        roundData.isRedeemed[msg.sender] = true;
        roundData.redeemCount += 1;

        uint256 redeemPrize = roundData.roundPrize / rankingAddresses.length;
        (bool success, ) = payable(msg.sender).call{value: redeemPrize}("");
        require(success, "Transfer failed.");
    }

    // Withdraw fee for team, available only two weeks after first person got 2048, last forever if fee is enough
    function withdraw() external onlyOwner {
        require(
            block.timestamp - first2048creationTimestamp > 1209600,
            "Not able to withdraw"
        );

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    function getTokenPoint(uint256 id) private pure returns (uint128) {
        return uint128(2**id);
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint64 amount = uint64(amounts[i]);
            uint128 tokenPoint = getTokenPoint(id) * amount;

            if (from != address(0)) {
                UserMintData storage fromData = userMintDataMapping[from];
                fromData.totalPoint -= tokenPoint;
                fromData.totalCount -= amount;
                if (id == MAX_LEVEL) {
                    token4096HoldAt[from] = 0;
                }
            }

            if (
                from == address(0) &&
                id == MAX_LEVEL - 1 &&
                first2048creationTimestamp == 0
            ) {
                first2048creationTimestamp = block.timestamp;
            }

            if (to != address(0)) {
                UserMintData storage toData = userMintDataMapping[to];
                toData.totalPoint += tokenPoint;
                toData.totalCount += amount;
                if (id == MAX_LEVEL && token4096HoldAt[to] == 0) {
                    token4096HoldAt[to] = block.timestamp;
                }
            }
        }

        if (to == address(0)) {
            return;
        }

        if (rankingAddresses.length == MAX_RANING_SIZE) {
            uint128 minPoint = type(uint128).max;
            uint256 minIndex = type(uint256).max;

            for (uint256 i = 0; i < rankingAddresses.length; i++) {
                address addr = rankingAddresses[i];
                uint128 addrPoint = userMintDataMapping[addr].totalPoint;

                if (addr == to) {
                    return;
                }

                if (addrPoint < minPoint) {
                    minPoint = addrPoint;
                    minIndex = i;
                }
            }

            if (userMintDataMapping[to].totalPoint > minPoint) {
                rankingAddressIndexMapping[rankingAddresses[minIndex]] =
                    minIndex +
                    1;
                rankingAddresses[minIndex] = to;
            }
        } else if (
            rankingAddresses.length < MAX_RANING_SIZE &&
            rankingAddressIndexMapping[to] == 0
        ) {
            rankingAddresses.push(to);
            rankingAddressIndexMapping[to] = rankingAddresses.length;
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                if (ids[0] == 0) {
                    level0MintCount += 1;
                }
            }
        }
    }
}
