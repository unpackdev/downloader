 //SPDX-License-Identifier: none

pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauserUpgradeable.sol";

contract TropixNFT is ERC1155PresetMinterPauserUpgradeable { 

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    string public name;
    string public symbol;
    string public contractURI;

    /**
     * @dev Grants `OPERATOR_ROLE` to the account that deploys the contract.
     */
    function initialize(string memory uri) public override initializer {
        __ERC1155PresetMinterPauser_init(uri);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id` and adds a default operator
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) public override {
        require(hasRole(MINTER_ROLE, _msgSender()), "TropixNFT: must have minter role to mint");

        _mint(to, id, amount, data);

        _operatorApprovals[to][msg.sender] = true;
    }  


    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint} and adds a default operator.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public override {
        require(hasRole(MINTER_ROLE, _msgSender()), "TropixNFT: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);

        _operatorApprovals[to][msg.sender] = true;
    }

    function move(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
    {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "TropixNFT: must have operator role to move");

        if (!_operatorApprovals[to][msg.sender]) {
            _operatorApprovals[to][msg.sender] = true;
        } 

        safeTransferFrom(from, to, id, amount, data);
    }

    function moveBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
    {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "TropixNFT: must have operator role to move");

        if (!_operatorApprovals[to][msg.sender]) {
            _operatorApprovals[to][msg.sender] = true; 
        }

        safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value) public override {
        require(hasRole(BURNER_ROLE, _msgSender()), "TropixNFT: must have burner role to burn");

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override {        
        require(hasRole(BURNER_ROLE, _msgSender()), "TropixNFT: must have burner role to burn");

        _burnBatch(account, ids, values);
    }

    function setURI(string memory newuri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TropixNFT: must have admin role to set uri");
        
        _setURI(newuri);
    }

    function setName(string calldata _name) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TropixNFT: must have admin role to set uri");

        name = _name;
    }

    function setSymbol(string calldata _symbol) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TropixNFT: must have admin role to set uri");

        symbol = _symbol;
    }

    function setContractURI(string calldata _contractURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TropixNFT: must have admin role to set uri");

        contractURI = _contractURI;
    }
}