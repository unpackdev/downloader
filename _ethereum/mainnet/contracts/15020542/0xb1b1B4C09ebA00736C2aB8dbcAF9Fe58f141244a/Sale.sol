// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ISarugami.sol";

contract Sale is Ownable, ReentrancyGuard {
    bytes32 public merkleRootAlphaTeam = "0x";
    uint256 public maxAlphaTeam = 4;

    bytes32 public merkleRootHeadMods = "0x";
    uint256 public maxHeadMods = 3;

    bytes32 public merkleRootMods = "0x";
    uint256 public maxMods = 2;

    bytes32 public merkleRootHonoraryOg = "0x";
    uint256 public maxHonoraryOg = 2;
    uint256 priceHonoraryOg = 26500000000000000;

    bytes32 public merkleRootOg = "0x";
    uint256 public maxOg = 2;
    uint256 priceOg = 53000000000000000;

    bytes32 public merkleRootWhitelist = "0x";
    uint256 public maxWhitelist = 1;
    uint256 priceWhitelist = 53000000000000000;

    bytes32 public merkleRootRaffle = "0x";
    uint256 public maxRaffle = 1;
    uint256 priceRaffle = 88000000000000000;

    uint256 public startFirstDay = 1656176400;
    uint256 public finishFirstDay = 1656266400;
    uint256 public startSecondDay = 1656268200;
    uint256 public finishSecondDay = 1656354600;
    ISarugami public sarugami;

    bool public isHolderMintActive = false;
    uint256 public holderPrice = 1000000000000000000;
    bytes32 public merkleRootHolder = "0x";

    bool public isPublicMintActive = false;
    bool public isLimitOnPublicMint = true;
    uint256 public publicPrice = 1000000000000000000;

    mapping(address => uint256) public walletMintCount;
    mapping(address => uint256) public walletMintCountRaffle;
    mapping(address => uint256) public walletHolderCount;
    mapping(address => uint256) public walletPublicCount;

    constructor(
        address sarugamiAddress
    ) {
        sarugami = ISarugami(sarugamiAddress);
    }

    function buy(bytes32[] calldata merkleProof, uint256 group, uint256 amount) public payable nonReentrant {
        require(block.timestamp > startFirstDay, "Sale not open");
        require(block.timestamp < finishSecondDay, "Sale ended");
        require(group > 0 && group <= 7, "Invalid group");
        require(amount > 0, "Invalid amount");
        require(isWalletListed(merkleProof, msg.sender, group) == true, "Invalid proof, your wallet isn't listed in any group");

        uint256 price = getPriceForGroup(group, amount);
        require(msg.value == price, "ETH sent does not match Sarugami value");

        //FIRST DAY ELSE SECOND DAY
        if (block.timestamp > startFirstDay && block.timestamp < finishFirstDay) {
            require(group <= 6, "Today is just for groups: Team, Honorary OGs, OGs and Whitelist");
            require(walletMintCount[msg.sender] + amount <= getMaxAmountForGroup(group), "Max amount reached for this wallet");

            //IF IS THE FIRST HOUR JUST ALPHA AND HEAD MOD CAN MINT FOR TESTS
            if (block.timestamp < (startFirstDay + 3600)) {
                require(group <= 2, "Alpha team + Head mod is minting now for tests purposes");
            }

            walletMintCount[msg.sender] += amount;
            sarugami.mint(msg.sender, amount);
        } else {
            require(group > 6, "You miss the minting date sorry.");
            require(block.timestamp > startSecondDay, "Public Raffle and Earlier Supporter Raffle not open");
            require(block.timestamp < finishSecondDay, "Public Raffle and Earlier Supporter Raffle ended");
            require(walletMintCountRaffle[msg.sender] + amount <= getMaxAmountForGroup(group), "Max 1 per wallet");

            walletMintCountRaffle[msg.sender] += amount;
            sarugami.mint(msg.sender, amount);
        }
    }

    function mintHolder(bytes32[] calldata merkleProof) public payable nonReentrant {
        require(isHolderMintActive, "Holder sale not open");
        require(walletHolderCount[msg.sender] + 1 <= 1, "Max 1 per wallet");
        require(msg.value == holderPrice, "ETH sent does not match Sarugami value");
        require(isWalletListed(merkleProof, msg.sender, 8) == true, "Invalid proof, your wallet isn't listed on holders group");

        walletHolderCount[msg.sender] += 1;
        sarugami.mint(msg.sender, 1);
    }

    function mintPublic(uint256 amount) public payable nonReentrant {
        require(isPublicMintActive, "Public sale not open");
        require(amount > 0, "Invalid amount");

        if (isLimitOnPublicMint) {
            require(walletPublicCount[msg.sender] + amount <= 2, "Max 2 per wallet");
            walletPublicCount[msg.sender] += amount;
        }

        require(msg.value == publicPrice * amount, "ETH sent does not match Sarugami value");

        sarugami.mint(msg.sender, amount);
    }

    function changePricePublic(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    function changePriceHolder(uint256 newPrice) external onlyOwner {
        holderPrice = newPrice;
    }

    function getMaxAmountForGroup(uint256 group) public view returns (uint256 amount) {
        if (group == 1) {
            return maxAlphaTeam;
        }

        if (group == 2) {
            return maxHeadMods;
        }

        if (group == 3) {
            return maxMods;
        }

        if (group == 4) {
            return maxHonoraryOg;
        }

        if (group == 5) {
            return maxOg;
        }

        if (group == 6) {
            return maxWhitelist;
        }

        if (group == 7) {
            return maxRaffle;
        }

        return 0;
    }

    function getPriceForGroup(uint256 group, uint256 amount) public view returns (uint256 price) {
        if (group == 1) {
            return 0;
        }

        if (group == 2) {
            return 0;
        }

        if (group == 3) {
            return 0;
        }

        if (group == 4) {
            return priceHonoraryOg * amount;
        }

        if (group == 5) {
            return priceOg * amount;
        }

        if (group == 6) {
            return priceWhitelist * amount;
        }

        if (group == 7) {
            return priceRaffle * amount;
        }

        return 1000000000000000000;
    }

    function isWalletListed(
        bytes32[] calldata merkleProof,
        address wallet,
        uint256 group
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));

        if (group == 1) {
            return MerkleProof.verify(merkleProof, merkleRootAlphaTeam, leaf);
        }

        if (group == 2) {
            return MerkleProof.verify(merkleProof, merkleRootHeadMods, leaf);
        }

        if (group == 3) {
            return MerkleProof.verify(merkleProof, merkleRootMods, leaf);
        }

        if (group == 4) {
            return MerkleProof.verify(merkleProof, merkleRootHonoraryOg, leaf);
        }

        if (group == 5) {
            return MerkleProof.verify(merkleProof, merkleRootOg, leaf);
        }

        if (group == 6) {
            return MerkleProof.verify(merkleProof, merkleRootWhitelist, leaf);
        }

        if (group == 7) {
            return MerkleProof.verify(merkleProof, merkleRootRaffle, leaf);
        }

        if (group == 8) {
            return MerkleProof.verify(merkleProof, merkleRootHolder, leaf);
        }

        return false;
    }

    function changePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function changeLimitPublicMint() external onlyOwner {
        isLimitOnPublicMint = !isLimitOnPublicMint;
    }

    function changeHolderMint() external onlyOwner {
        isHolderMintActive = !isHolderMintActive;
    }

    function setMerkleTreeRootAlphaTeam(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootAlphaTeam = newMerkleRoot;
    }

    function setMerkleTreeRootHolder(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootHolder = newMerkleRoot;
    }

    function setMerkleTreeRootHeadMods(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootHeadMods = newMerkleRoot;
    }

    function setMerkleTreeRootMods(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootMods = newMerkleRoot;
    }

    function setMerkleTreeRootHonoraryOg(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootHonoraryOg = newMerkleRoot;
    }

    function setMerkleTreeRootOg(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootOg = newMerkleRoot;
    }

    function setMerkleTreeRootWhitelist(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootWhitelist = newMerkleRoot;
    }

    function setMerkleTreeRootRaffle(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootRaffle = newMerkleRoot;
    }

    function setStartFirstDay(uint256 timestamp) external onlyOwner {
        startFirstDay = timestamp;
    }

    function setFinishFirstDay(uint256 timestamp) external onlyOwner {
        finishFirstDay = timestamp;
    }

    function setStartSecondDay(uint256 timestamp) external onlyOwner {
        startSecondDay = timestamp;
    }

    function setFinishSecondDay(uint256 timestamp) external onlyOwner {
        finishSecondDay = timestamp;
    }

    function withdrawStuckToken(address recipient, address token) external onlyOwner() {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    function removeDustFunds(address treasury) external onlyOwner {
        (bool success,) = treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }

    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;

        (bool devShare,) = 0xDEcB0fB8d7BB68F0CE611460BE8Ca0665A72d47E.call{
        value : funds * 5 / 100
        }("");

        (bool makiShare,) = 0x83fEa2d7cB61174c55E6fFA794840FF91d889d00.call{
        value : funds * 15 / 100
        }("");

        (bool nikoShare,) = 0xeb3853d765870fF40318CF37f3b83B02Fd18b46C.call{
        value : funds * 3 / 100
        }("");

        (bool frankShare,) = 0xCE1f60EC76a7bBacED41816775b842067d8D17B3.call{
        value : funds * 3 / 100
        }("");

        (bool peresShare,) = 0x7F1a6c8DFF62e1595A699e9f0C93B654CcfC5Fe1.call{
        value : funds * 2 / 100
        }("");

        (bool guuhShare,) = 0x907c71f22d893CB75340C820fe794BC837079e8E.call{
        value : funds * 1 / 100
        }("");

        (bool luccaShare,) = 0x3bB05e56cb60C1e2D00d3e4d0B8Ae7501B2f5F50.call{
        value : funds * 1 / 100
        }("");

        (bool costShare,) = 0x3bB05e56cb60C1e2D00d3e4d0B8Ae7501B2f5F50.call{
        value : funds * 10 / 100
        }("");

        (bool pedroShare,) = 0x289660e62ff872536330938eb843607FC53E0a34.call{
        value : funds * 30 / 100
        }("");

        (bool digaoShare,) = 0xDEEf09D53355E838db08E1DBA9F86a5A7DfF2124.call{
        value : address(this).balance
        }("");

        require(
            devShare &&
            makiShare &&
            nikoShare &&
            frankShare &&
            peresShare &&
            guuhShare &&
            luccaShare &&
            costShare &&
            pedroShare &&
            digaoShare,
            "funds were not sent properly"
        );
    }
}