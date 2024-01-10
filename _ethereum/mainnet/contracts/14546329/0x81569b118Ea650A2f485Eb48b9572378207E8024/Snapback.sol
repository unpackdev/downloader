//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Counters.sol";

contract Snapback is ERC1155 {
    using Counters for Counters.Counter;

    uint256 public tokenPrice;
    // address contractAddress;
    address public owner;

    string private constant IPFS_PREFIX = "https://ipfs.io/ipfs/";

    uint256 public constant TOKENS_TYPE_CAP = 50;
    uint256 public constant TOKENS_USER_CAP = 5;

    uint256 public constant AVASTARS = 1;
    uint256 public constant DRIPPERS = 2;
    uint256 public constant UNOFFICAL_PUNKS = 3;
    uint256 public constant COCAIN_COWBOY = 4;

    mapping(uint256 => Counters.Counter) private _countByType;
    mapping(address => mapping(uint256 => Counters.Counter)) private _countByUser;

    constructor(uint256 _tokenPrice) ERC1155(string(abi.encodePacked(IPFS_PREFIX, "QmPossjCcLxQsGrcGB9pvqKCXfoorbsyxp3iALQ5WiVvk6/{id}.json"))) {
        owner = msg.sender;
        // contractAddress = storeAddress;
        tokenPrice = _tokenPrice;
    }

    function mintToken(uint256 id) payable public {
        require(
            msg.value == tokenPrice,
            "Please submit asking price in order to complete the purchase"
        );
        require(
            _countByType[id].current() < TOKENS_TYPE_CAP,
            "No tokens left"
        );
        require(
            _countByUser[msg.sender][id].current() < TOKENS_USER_CAP,
            "Tokens limit exceeded"
        );
        require(
            id < 5,
            "Invalid ID"
        );

        // Pay price to owner
        payable(owner).transfer(msg.value);

        // Mint NFT
        _mint(msg.sender, id, 1, "");

        // Increment
        _countByType[id].increment();
        _countByUser[msg.sender][id].increment();
        // setApprovalForAll(contractAddress, true);
    }

    function burnToken(uint256 id) public {
        _burn(msg.sender, id, 1);

        // Decrement
        // _countByType[id].decrement();
        // _countByUser[msg.sender][id].decrement();
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return string(
            abi.encodePacked(
                IPFS_PREFIX,
                "QmPossjCcLxQsGrcGB9pvqKCXfoorbsyxp3iALQ5WiVvk6/",
                Strings.toString(id),
                ".json"
            )
        );
    }
}
