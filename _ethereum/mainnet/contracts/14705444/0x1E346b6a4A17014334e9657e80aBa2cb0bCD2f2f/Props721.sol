// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "./ERC721A.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Base.sol";
import "./IAdmin.sol";
import "./IAllowlist.sol";

import "./console.sol";

contract Props721 is
    Base,
    ERC721A,
    Pausable {

    using Strings for uint256;

    // contract doesn't support IAdmin interface
    error InvalidAdminContract();
    // invalid category was specified
    error InvalidCategory();

    // emitted upon a successful mint
    event Minted(address indexed account, string tokens);

    address public adminContract;
    string private baseURI_;

    // how many tokens an address has minted
    mapping(address => uint256) public minted;
    mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;

    constructor (
        string memory baseURI,
        address _adminContract,
        string memory contractName,
        string memory tokenName
    ) ERC721A(contractName, tokenName) {
        if (!IAdmin(_adminContract).supportsInterface(type(IAdmin).interfaceId)) revert InvalidAdminContract();
        baseURI_ = baseURI;
        adminContract = _adminContract;

    }

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(Base, ERC721A) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev sets starting token ID for ERC721A
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _quantity, bytes32[][] memory _proofs) external payable nonReentrant {
        // are the mint parameters met?
        IAdmin(adminContract).revertOnMintCheckFailure(0, _quantity, totalSupply(), paused());
        // is caller allowed to mint _quantity?
        IAdmin(adminContract).revertOnAllocationCheckFailure(msg.sender, _proofs, (_quantity + minted[address(msg.sender)]));
        IAdmin(adminContract).revertOnMaxWalletMintCheckFailure(0, _quantity, minted[address(msg.sender)]);

        // is caller sending the correct amount of funds?
        IAdmin(adminContract).revertOnPaymentFailure(0, 0, _quantity, msg.value, false);
        // send funds to split contract
        Address.sendValue(IAdmin(adminContract).getSplitContract(), msg.value);
        // mint _quantity tokens
        string memory tokensMinted = "";
        unchecked {

            for (uint i = totalSupply() + 1; i <= totalSupply() + _quantity; i++) {
                tokensMinted = string(abi.encodePacked(tokensMinted, Strings.toString(i), ","));
            }
            minted[address(msg.sender)] += _quantity;
            _safeMint(msg.sender, _quantity);
        }
        console.log("tokensMinted", tokensMinted);
        emit Minted(msg.sender, tokensMinted);
    }

    function mintArbitraryAllocations(uint256[] calldata _quantities, bytes32[][] calldata _proofs, uint256[] calldata _allotments, uint256[] calldata _allowlistIds) external payable nonReentrant {

        uint256 _cost = 0;
        uint256 _quantity = 0;
        uint256 _allowed = 0;

        for (uint i = 0; i < _quantities.length; i++) {
          _quantity += _quantities[i];
          _allowed += _allotments[i];
        }

        IAdmin(adminContract).revertOnMintCheckFailure(0, _quantity, totalSupply(), paused());
        IAdmin(adminContract).revertOnMaxWalletMintCheckFailure(0, _quantity, minted[address(msg.sender)]);
        // IAdmin(adminContract).revertOnTotalAllocationCheckFailure(minted[address(msg.sender)], _quantities[i], _allowed);

        for (uint i = 0; i < _quantities.length; i++) {
            //is caller allowed to mint arb quantity?
            //if ((_quantities[i] + mintedByAllowlist[address(msg.sender)][_allowlistIds[i]]) > _allotments[i]) revert IAdmin.AllocationExceeded();
            IAdmin(adminContract).revertOnArbitraryAllocationCheckFailure(msg.sender, mintedByAllowlist[address(msg.sender)][_allowlistIds[i]], _quantities[i], _proofs[i], _allowlistIds[i], _allotments[i]);

            //increment total cost

            _cost += IAdmin(adminContract).getPricelistByAllowlistId(_allowlistIds[i]).price * _quantities[i];
        }
        // is caller sending the correct amount of funds?
        IAdmin(adminContract).revertOnArbitraryPaymentFailure(_cost, msg.value);

        // send funds to split contract
        Address.sendValue(IAdmin(adminContract).getSplitContract(), msg.value);

        // mint _quantity tokens
        string memory tokensMinted = "";
        unchecked {
            for (uint i = totalSupply() + 1; i <= totalSupply() + _quantity; i++) {
                tokensMinted = string(abi.encodePacked(tokensMinted, Strings.toString(i), ","));
            }
            for (uint i = 0; i < _quantities.length; i++) {
              mintedByAllowlist[address(msg.sender)][_allowlistIds[i]] += _quantities[i];
            }
            minted[address(msg.sender)] += _quantity;
            _safeMint(msg.sender, _quantity);
        }
        emit Minted(msg.sender, tokensMinted);
    }

    /**
     * @dev sets admin contract address
     */
    function setAdminContract(address _address) external onlyRole(CONTRACT_ADMIN_ROLE) {
        if (!IAdmin(_address).supportsInterface(type(IAdmin).interfaceId)) revert InvalidAdminContract();
        adminContract = _address;
    }

    /**
     * @dev see {IERC721Metadata}
     */
    function setBaseURI(string memory baseURI) external onlyRole(CONTRACT_ADMIN_ROLE) {
        baseURI_ = baseURI;
    }

    /**
     * @dev see {IERC721Metadata}
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI_, tokenId.toString(), '.json'));
    }   

    /**
    * @dev see {IAdmin-getContractURI}
    */
    function contractURI() external view returns (string memory) {
        return IAdmin(adminContract).getContractURI();
    }

    /**
    * @dev pauses the contract
    */
    function pause() external onlyRole(CONTRACT_ADMIN_ROLE) {
        _pause();
    }

    /**
    * @dev unpauses the contract
    */
    function unpause() external onlyRole(CONTRACT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev overrides {ERC721-_baseURI}
     */
    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return baseURI_;
    }

}
