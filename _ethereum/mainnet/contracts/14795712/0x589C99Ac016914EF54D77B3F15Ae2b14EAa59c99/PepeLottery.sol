// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./VRFv2Consumer.sol";

contract PepeLottery is ERC1155, Ownable, VRFv2Consumer {
    uint256 immutable MAX_SUPPLY = 3333;
    uint256 public constant POOR_PEPE = 0;
    uint256 public constant NORMAL_PEPE = 1;
    uint256 public constant RICH_PEPE = 2;

    uint256 public PP_PRICE = .003 ether;
    uint256 public NP_PRICE = .0069 ether;
    uint256 public RP_PRICE = .02 ether;

    uint256 public numMinted;
    uint256 public numEntries;
    uint256 public offset;

    string public cid = "QmRGT9afCe5H1euW3V7MwtzDeSyCiR5HFnjarXPNiVtVdx";
    string public name = "Pepe Lottery";
    string public symbol = "PPL";

    address public winner;
    bool public saleLive;
    bool public winnerSet;

    mapping(address => bool) public hasMinted;
    mapping(uint256 => address) public walletEntries;

    modifier checkSale(uint256 quantity) {
        require(tx.origin == msg.sender, "No smart contracts");
        require(saleLive, "Sale is not live");
        require(quantity + numMinted <= MAX_SUPPLY, "OOS");
        require(quantity <= 20, "Max mint is 20");
        require(!hasMinted[msg.sender], "Address has minted");
        _;
    }

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) ERC1155() VRFv2Consumer(subscriptionId, vrfCoordinator, keyHash) {}

    function mint(uint256 id, uint256 quantity)
        external
        payable
        checkSale(quantity)
    {
        uint256 entries;
        if (id == 0) {
            require(msg.value == PP_PRICE * quantity, "Invalid eth amount");
            entries = quantity;
        }
        if (id == 1) {
            require(msg.value == NP_PRICE * quantity, "Invalid eth amount");
            entries = quantity * 5;
        }
        if (id == 2) {
            require(msg.value == RP_PRICE * quantity, "Invalid eth amount");
            entries = quantity * 15;
        }
        hasMinted[msg.sender] = true;
        _mint(msg.sender, id, quantity, "");
        numMinted += quantity;
        numEntries += entries;
        walletEntries[numEntries - 1] = msg.sender;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        offset = randomWords[0];
        winnerSet = true;
    }

    function flipSale() external onlyOwner {
        saleLive = !saleLive;
    }

    function setCID(string calldata _cid) external onlyOwner {
        cid = _cid;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://", cid, "/{id}.json"));
    }

    function getWinner() internal view returns (address) {
        uint256 ticket = offset % (numEntries - 1);
        while (true) {
            if (walletEntries[ticket] != address(0))
                return walletEntries[ticket];
            else ticket++;
        }
    }

    function withdraw() external onlyOwner {
        require(winnerSet, "Need to pick winner before withdraw");
        winner = getWinner();
        payable(owner()).transfer((address(this).balance * 304) / 10000);
        payable(winner).transfer(address(this).balance);
    }
}
