// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

/*
 _       _  _                                              ___
( )  _  ( )( )                                _           (  _`\                      _
| | ( ) | || |__     _      _    _ _     ___ (_)   __     | | ) |   __   _ __  _ _   (_)   __    ___
| | | | | ||  _ `\ /'_`\  /'_`\ ( '_`\ /',__)| | /'__`\   | | | ) /'__`\( '__)( '_`\ | | /'__`\/',__)
| (_/ \_) || | | |( (_) )( (_) )| (_) )\__, \| |(  ___/   | |_) |(  ___/| |   | (_) )| |(  ___/\__, \
`\___x___/'(_) (_)`\___/'`\___/'| ,__/'(____/(_)`\____)   (____/'`\____)(_)   | ,__/'(_)`\____)(____/
                                | |                                           | |
                                (_)                                           (_)

🐖 Whoopsie Derpies is a hand-drawn art collection, inspired by drawing animals for our twin toddlers whilst getting bumped around and receiving conflicting requests.
🦙 The animals are cute and just a little bit derpy.
*/

contract WhoopsieDerpies is ERC1155, Ownable {
    string public contractUri;
    uint256 public constant DERPIE_PRICE = 0.01 ether;
    uint256 public constant MAX_TOKEN_ID_PLUS_ONE = 20; // 20 tokens numbered 0-19 inclusive

    mapping(uint256 => uint256) public tokenIdToExistingSupply;
    mapping(uint256 => uint256) public tokenIdToMaxSupplyPlusOne; // set in the constructor

    constructor()
        ERC1155(
            "ipfs://QmWAwLRmooeGNC2dRbfxE1e6ni5KXRQ9Fx6CYwk4yykDe5/{id}.json"
        )
    {
        contractUri = "ipfs://QmZAHpG5uZyjAShEFSenpLJC1KhGDhUzUJVPcKAg3TZKDN"; // json contract metadata file for OpenSea

        tokenIdToMaxSupplyPlusOne[0] = 14;
        tokenIdToMaxSupplyPlusOne[1] = 25;
        tokenIdToMaxSupplyPlusOne[2] = 6;
        tokenIdToMaxSupplyPlusOne[3] = 18;
        tokenIdToMaxSupplyPlusOne[4] = 17;
        tokenIdToMaxSupplyPlusOne[5] = 10;
        tokenIdToMaxSupplyPlusOne[6] = 12;
        tokenIdToMaxSupplyPlusOne[7] = 21;
        tokenIdToMaxSupplyPlusOne[8] = 17;
        tokenIdToMaxSupplyPlusOne[9] = 9;
        tokenIdToMaxSupplyPlusOne[10] = 15;
        tokenIdToMaxSupplyPlusOne[11] = 11;
        tokenIdToMaxSupplyPlusOne[12] = 17;
        tokenIdToMaxSupplyPlusOne[13] = 20;
        tokenIdToMaxSupplyPlusOne[14] = 20;
        tokenIdToMaxSupplyPlusOne[15] = 8;
        tokenIdToMaxSupplyPlusOne[16] = 15;
        tokenIdToMaxSupplyPlusOne[17] = 13;
        tokenIdToMaxSupplyPlusOne[18] = 10;
        tokenIdToMaxSupplyPlusOne[19] = 19;

        uint256[] memory _ids = new uint256[](20);
        uint256[] memory _amounts = new uint256[](20);
        for (uint256 i = 0; i < MAX_TOKEN_ID_PLUS_ONE; ++i) {
            _ids[i] = i;
            _amounts[i] = 1;
            tokenIdToExistingSupply[i] = 1;
        }
        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function setContractURI(string calldata _newURI) external onlyOwner {
        contractUri = _newURI; // updatable in order to change general project info for marketplaces like OpenSea
    }

    /// @dev function for OpenSea that returns uri of the contract metadata
    function contractURI() external view returns (string memory) {
        return contractUri; // OpenSea
    }

    /// @dev function for OpenSea that returns the total quantity of a token ID currently in existence
    function totalSupply(uint256 _id) external view returns (uint256) {
        require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 20");
        return tokenIdToExistingSupply[_id];
    }

    function mint(uint256 _id, uint256 _amount) external payable {
        require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 20");

        uint256 existingSupply = tokenIdToExistingSupply[_id];
        require(
            existingSupply + _amount < tokenIdToMaxSupplyPlusOne[_id],
            "supply exceeded"
        );

        require(msg.value == _amount * DERPIE_PRICE, "incorrect ETH");
        require(msg.sender == tx.origin, "no smart contracts");
        unchecked {
            existingSupply += _amount;
        }
        tokenIdToExistingSupply[_id] = existingSupply;
        _mint(msg.sender, _id, _amount, "");
    }

    function ownerMint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 20");

        uint256 existingSupply = tokenIdToExistingSupply[_id];
        require(
            existingSupply + _amount < tokenIdToMaxSupplyPlusOne[_id],
            "supply exceeded"
        );
        unchecked {
            existingSupply += _amount;
        }
        tokenIdToExistingSupply[_id] = existingSupply;
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        payable
    {
        uint256 sumAmounts;
        uint256 arrayLength = _ids.length;
        for (uint256 i = 0; i < arrayLength; ++i) {
            sumAmounts += _amounts[i];
        }

        require(msg.value == sumAmounts * DERPIE_PRICE, "incorrect ETH");

        for (uint256 i = 0; i < arrayLength; ++i) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            uint256 existingSupply = tokenIdToExistingSupply[_id];

            require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 20");
            require(
                existingSupply + _amount < tokenIdToMaxSupplyPlusOne[_id],
                "supply exceeded"
            );
            require(msg.sender == tx.origin, "no smart contracts");

            unchecked {
                existingSupply += _amount;
            }
            tokenIdToExistingSupply[_id] = existingSupply;
        }
        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function ownerMintBatch(
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external onlyOwner {
        uint256 arrayLength = _ids.length;

        for (uint256 i = 0; i < arrayLength; ++i) {
            uint256 existingSupply = tokenIdToExistingSupply[_ids[i]];
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];

            require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 20");
            require(
                existingSupply + _amount < tokenIdToMaxSupplyPlusOne[_id],
                "supply exceeded"
            );
            require(msg.sender == tx.origin, "no smart contracts");

            unchecked {
                existingSupply += _amount;
            }
            tokenIdToExistingSupply[_id] = existingSupply;
        }
        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function withdraw() external payable onlyOwner {
        (bool succeed, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(succeed, "failed to withdraw ETH");
    }
}
