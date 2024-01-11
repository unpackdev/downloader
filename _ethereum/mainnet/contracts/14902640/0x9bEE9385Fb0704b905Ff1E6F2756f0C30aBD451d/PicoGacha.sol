// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC1155Receiver.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

error OnlyEOA();
error OnlyAllowedNFT();
error NotEnoughPrize();
error NoMoreRoll();

contract PicoGacha is ERC1155Receiver, Ownable {
    struct Pico {
        address token;
        uint256 id;
        uint256 amount;
        bool allowed;
    }

    mapping(address => mapping(uint256 => uint256)) public tokenToIdToPico;
    mapping(uint256 => Pico) public picos;
    uint256 public picosCounter;

    mapping(uint256 => uint256) public prizePool;
    uint256 public prizePoolCounter;

    mapping(address => uint256) public allowedAddress;
    mapping(address => uint256) public rolled;

    event Roll(address indexed roller, address indexed token, uint256 indexed id);
    event AddNFT(address indexed token, uint256 indexed id, uint256 indexed amount);

    function roll() public {
        if (tx.origin != msg.sender) revert OnlyEOA();
        if (rolled[msg.sender] >= allowedAddress[msg.sender]) revert NoMoreRoll();
        if (prizePoolCounter == 0) revert NotEnoughPrize();
        
        // Get winning prizePool index
        uint256 randomPrizeId = random(prizePoolCounter);

        uint256 picoId = prizePool[randomPrizeId];
        picos[picoId].amount--;
        
        // Reduce prizePool by one, replace the winning prize with the last prize
        prizePoolCounter--;
        prizePool[randomPrizeId] = prizePool[prizePoolCounter];

        rolled[msg.sender]++;

        IERC1155(picos[picoId].token).safeTransferFrom(
            address(this),
            msg.sender,
            picos[picoId].id,
            1,
            ""
        );

        emit Roll(msg.sender, picos[picoId].token, picos[picoId].id);
    }

    function rolls(uint256 times) external {
        for (uint256 i = 0; i < times; i++) {
            roll();
        }
    }

    function random(uint256 size) public view returns (uint256) {
        // UNSAFE RANDOMNESS. DO NOT USE FOR VALUABLE ASSET.
        return uint256(keccak256(abi.encodePacked(
            block.timestamp, rolled[msg.sender], "PICO GACHA"
        ))) % size;
    }

    function setAllowedNFTs(address[] calldata tokens, uint256[] calldata ids, bool[] calldata values) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 picoId = tokenToIdToPico[tokens[i]][ids[i]];

            if (picoId == 0) {
                picoId = picosCounter + 1;
                tokenToIdToPico[tokens[i]][ids[i]] = picoId;
                // initialise new nft
                picos[picoId] = Pico(tokens[i], ids[i], 0, values[i]);
                tokenToIdToPico[tokens[i]][ids[i]] = picosCounter + 1;
                picosCounter++;
            } else {
                picos[picoId].allowed = values[i];
            }
        }
    } 

    // @param amounts - total roll allowed for address
    function setAllowedAddresses(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowedAddress[addresses[i]] = amounts[i];
        }
    }

    function addNFT(address token, uint256 id, uint256 amount) internal {
        uint256 picoId = tokenToIdToPico[token][id];
        if (!picos[picoId].allowed) revert OnlyAllowedNFT();
        assert(amount > 0);

        for (uint256 i = 0; i < amount; i++) {
            prizePool[i + prizePoolCounter] = picoId;
        }

        picos[picoId].amount += amount;
        prizePoolCounter += amount;

        emit AddNFT(token, id, amount);
    }

    function onERC1155Received(
        address ,
        address ,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public virtual override returns (bytes4) {
        addNFT(msg.sender, id, value);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address ,
        address ,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) public virtual override returns (bytes4) {
        for (uint256 i = 0; i < ids.length; i++) {
            addNFT(msg.sender, ids[i], values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    // Only call after event ended or to rescue wrongly sent NFT
    function rescueNFTs(
        address token,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        IERC1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }
}
