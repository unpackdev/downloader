/**
  ________       .__          __      __  .__           ________                       
 /  _____/_____  |  | _____  |  | ___/  |_|__| ____    /  _____/_____    ____    ____  
/   \  ___\__  \ |  | \__  \ |  |/ /\   __\  |/ ___\  /   \  ___\__  \  /    \  / ___\ 
\    \_\  \/ __ \|  |__/ __ \|    <  |  | |  \  \___  \    \_\  \/ __ \|   |  \/ /_/  >
 \______  (____  /____(____  /__|_ \ |__| |__|\___  >  \______  (____  /___|  /\___  / 
        \/     \/          \/     \/              \/          \/     \/     \//_____/  

Art By: Community Members and Prints by Chris Dyer
Contract By: Travis Delly
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzep
import "./ECDSAUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";

import "./Base.sol";

import "./console.sol";

contract GalakticGadgets is GalakticBase, ERC1155SupplyUpgradeable {
    /** ===== STRUCTS ==== */
    struct Gadget {
        // 1
        string name;
        string ipfsMetadataHash;
        // 1
        uint128 mintPrice;
        uint64 id;
        uint64 maxSupply;
        // 1
        uint8 mintPriceGG;
        bool mintableGG;
        bool mintable;
    }

    /** ===== VARIABLES ==== */
    string public name_;
    string public symbol_;
    uint256 counter;

    mapping(uint256 => Gadget) public gadgets;
    mapping(address => uint256) public usedCredits;

    /** ===== INITIALIZE ==== */
    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC1155_init('ipfs://');
        __GalakticBase_init();
        name_ = _name;
        symbol_ = _symbol;
    }

    /** @dev contract name */
    function name() public view returns (string memory) {
        return name_;
    }

    /** @dev contract symbol */
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    /**
     * @notice adds a new gadget
     */
    function addGadget(
        string memory _name,
        string memory _ipfsMetadataHash,
        uint128 _mintPrice,
        uint8 _mintPriceGG,
        uint64 _maxSupply,
        bool _mintableGG,
        bool _mintable
    ) public onlyOwner {
        Gadget storage util = gadgets[counter];
        util.id = uint64(counter);
        util.ipfsMetadataHash = _ipfsMetadataHash;
        util.name = _name;
        util.mintPrice = _mintPrice;
        util.mintPriceGG = _mintPriceGG;
        util.maxSupply = _maxSupply;
        util.mintableGG = _mintableGG;
        util.mintable = _mintable;

        counter++;
    }

    /**
     * @notice edit an existing gadget
     */
    function editGadget(
        string memory _name,
        string memory _ipfsMetadataHash,
        uint128 _mintPrice,
        uint8 _mintPriceGG,
        uint64 _maxSupply,
        bool _mintableGG,
        bool _mintable,
        uint256 _idx
    ) external onlyOwner {
        require(exists(_idx), 'EditGadget: Gadget does not exist');
        gadgets[_idx].ipfsMetadataHash = _ipfsMetadataHash;
        gadgets[_idx].mintPrice = _mintPrice;
        gadgets[_idx].mintPriceGG = _mintPriceGG;
        gadgets[_idx].maxSupply = _maxSupply;
        gadgets[_idx].name = _name;
        gadgets[_idx].mintableGG = _mintableGG;
        gadgets[_idx].mintable = _mintable;
    }

    /**
     * @notice make gadget mintable
     */
    function updateMintable(uint256[] calldata _idx, bool[] calldata _mintable)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _idx.length; i++) {
            gadgets[_idx[i]].mintable = _mintable[i];
        }
    }

    /**
     * @notice make gadget mintable
     */
    function updateMintableGG(
        uint256[] calldata _idx,
        bool[] calldata _mintable
    ) external onlyOwner {
        for (uint256 i = 0; i < _idx.length; i++) {
            gadgets[_idx[i]].mintableGG = _mintable[i];
        }
    }

    /**
     * @notice mint gadget tokens
     *
     * @param gadgetIdx the gadget id to mint
     * @param amount the amount of tokens to mint
     */
    function mint(
        uint256 gadgetIdx,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(exists(gadgetIdx), 'Mint: Gadget does not exist');
        require(
            totalSupply(gadgetIdx) + amount <= gadgets[gadgetIdx].maxSupply,
            'Mint: Max supply reached'
        );

        _mint(to, gadgetIdx, amount, '');
    }

    /**
     * @notice mint gadget tokens
     *
     * @param gadgetIdx the gadget id to mint
     * @param amount the amount of tokens to mint
     */
    function bulkMint(
        uint256 gadgetIdx,
        uint256 amount,
        address[] calldata to
    ) external onlyOwner {
        require(exists(gadgetIdx), 'Mint: Gadget does not exist');

        for (uint256 i = 0; i < to.length; i++) {
            require(gadgets[gadgetIdx].mintable, 'Gadget is not mintable');
            require(
                totalSupply(gadgetIdx) + amount <= gadgets[gadgetIdx].maxSupply,
                'Mint: Max supply reached'
            );

            _mint(to[i], gadgetIdx, amount, '');
        }
    }

    /** @dev purchase gadgets using credits
        @param gadgetIds {uint256[]} id's to mint
        @param amounts {uint256[]} amounts to mint for each id
        @param signature {bytes} messagehash
        @param credits {uint256} # of credits from messagehash
    */
    function purchaseWithCredits(
        uint256[] calldata gadgetIds,
        uint256[] calldata amounts,
        bytes memory signature,
        uint256 credits
    ) external whenNotPaused {
        // Ensure whitelist
        bytes32 messageHash = sha256(abi.encode(msg.sender, credits));
        require(
            ECDSAUpgradeable.recover(messageHash, signature) == owner,
            'Mint: Invalid Signature, are you whitelisted bud?'
        );

        for (uint256 i = 0; i < gadgetIds.length; i++) {
            uint256 id = gadgetIds[i];
            uint256 amount = amounts[i];

            require(
                gadgets[id].mintableGG,
                'Gadget is not mintable with credits'
            );
            require(
                totalSupply(id) + amount <= gadgets[id].maxSupply,
                'Mint: Max supply reached'
            );

            usedCredits[msg.sender] += amount * gadgets[id].mintPriceGG;

            require(
                usedCredits[msg.sender] <= credits,
                'Over Purchased, Chose less items.'
            );

            _mint(msg.sender, id, amount, '');
        }
    }

    /** @dev purchase gadgets 
        @param gadgetIds {uint256[]} id's to mint
        @param amounts {uint256[]} amounts to mint for each id
    */
    function purchase(uint256[] calldata gadgetIds, uint256[] calldata amounts)
        external
        payable
        whenNotPaused
    {
        uint256 cost = 0;
        for (uint256 i = 0; i < gadgetIds.length; i++) {
            uint256 id = gadgetIds[i];
            uint256 amount = amounts[i];

            require(gadgets[id].mintable, 'Gadget is not mintable with ETH');
            require(
                totalSupply(id) + amount <= gadgets[id].maxSupply,
                'Mint: Max supply reached'
            );

            cost += gadgets[id].mintPrice * amount;

            _mint(msg.sender, id, amount, '');
        }

        require(
            msg.value >= cost,
            "Mint: Insufficient ETH amount, don't cheap out on us!"
        );
    }

    /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        payable(to).transfer(balance);
    }

    /**
     * @notice return total supply for all existing gadgets
     */
    function totalSupplyAll() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](counter);

        for (uint256 i; i < counter; i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }

    /**
     *   @notice gets habitatgadgets
     */
    function getGadgets() external view returns (Gadget[] memory) {
        Gadget[] memory _utils = new Gadget[](counter);

        for (uint256 i = 0; i < counter; i++) {
            _utils[i] = gadgets[i];
        }

        return _utils;
    }

    /** @notice get current idx */
    function getCurrentCounter() external view returns (uint256) {
        return counter;
    }

    /**
     * @notice indicates weither any token exist with a given id, or not
     */
    function exists(uint256 id) public view override returns (bool) {
        return gadgets[id].maxSupply > 0;
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the gadget id to return metadata for
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), 'URI: nonexistent token');

        return
            string(
                abi.encodePacked(super.uri(_id), gadgets[_id].ipfsMetadataHash)
            );
    }
}
