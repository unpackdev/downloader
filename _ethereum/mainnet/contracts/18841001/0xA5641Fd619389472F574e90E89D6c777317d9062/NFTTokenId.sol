// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";

import "./ContractMetadata.sol";
import "./PrimarySale.sol";
import "./PermissionsEnumerable.sol";
import "./SignatureMintWithTokenId.sol";
import "./CurrencyTransferLib.sol";
import "./Genes.sol";

contract NFTTokenId is 
    Initializable,
    PrimarySale,
    ContractMetadata,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable, 
    PermissionsEnumerable,
    SignatureMintWithTokenIds,
    Genes
{
    
    using StringsUpgradeable for uint256;



    bytes32 public TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");

    


    bool public isInternal = false;
    uint256 public remainingETH = 0;
    mapping(uint256 => Entity) private entitys;

    modifier setupExecution() {
        require(!isInternal, "Unsafe call");

        remainingETH = msg.value;
        isInternal = true;
        _;
        remainingETH = 0;
        isInternal = false;
    }

    function initialize(
        string memory _name,                            // 名称
        string memory _symbol,                          // 符号
        string memory _contractURI,                     // 合约URI

        address _admin                                 // 默认管理员

    ) external initializer {

        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();

        
        
        __SignatureMintNFT_init();                                              // SignatureMintNFTUpgradeable
        _setupContractURI(_contractURI);

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _admin);                             
        _setupRole(TRANSFER_ROLE, _admin);                                  // transfer role is not required
        _setupRole(TRANSFER_ROLE, address(0));                              // transfer role is not required

        _setupPrimarySaleRecipient(0xC2E7C3577cf365483625010cF945f8139018f6Ed);                             // 设置主要销售接收者


        TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
        MINTER_ROLE = keccak256("MINTER_ROLE");

    }

    /// @dev Returns whether a given address is authorized to sign mint requests. extend from SignatureMint
    function _isAuthorizedSigner(address _signer) public view override returns (bool) {
        return this.hasRole(MINTER_ROLE, _signer);
    }
    
    /// @dev Returns whether a given address is authorized to sign mint requests. extend from SignatureMint
    function _isAuthorizedSigner2(address _signer) public view override returns (bool) {
        return this.hasRole(MINTER_ROLE, _signer);
    }

    /// @dev Mint with signatrue            // extend from SignatureMint
    function mint(MintRequest calldata _req, bytes calldata _signature)    
        external
        payable
        returns (address signer)
    {
        uint256 tokenId = _req.tokenId;
        address receiver = _req.userAddress;

        signer = _processRequest(_req, _signature);

        _safeMint(receiver, _req.tokenId);

        _transferFunds(_req.paymentToken, _req.nftPrice);

        emit TokensMintedWithSignature(signer, receiver, tokenId, _req);
    }

     function bulkMint(MintOperation[] calldata ops)
        external
        payable
        setupExecution
    {
        uint256 opsLength = ops.length;

        if (opsLength == 0) revert("No mint ops to execute");

        for (uint8 i = 0; i < opsLength; i++) {

            bytes memory data = abi.encodeWithSelector(this.mint.selector, ops[i].requst, ops[i].sig);

            (bool success, bytes memory returndata) = address(this).delegatecall(data);

            if (success) {
                // return returndata;
            } else {
                if (returndata.length > 0) {
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                }
            }
        }

        _returnDust();
    }
    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
    }

    function _canSetContractURI() internal view override returns (bool) {
        return this.hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

      /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return this.hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _transferFunds(address _paymentToken, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        if (_paymentToken == address(0)) {
            require(remainingETH >= _amount, "Insufficient value");
            remainingETH -= _amount;
        }
        address saleRecipient = primarySaleRecipient();
        CurrencyTransferLib.transferCurrency(_paymentToken, msg.sender, saleRecipient, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);

        // if (!this.hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
        //     if (!this.hasRole(TRANSFER_ROLE, from) && !this.hasRole(TRANSFER_ROLE, to)) {
        //         revert("!Transfer-Role");
        //     }
        // }
    }

    function rebirth(uint256 _tokenId, uint256 _genes, address _owner, bytes calldata _sig) 
        external 
    {
        bool success;
        address signer;
        (success, signer) = verifyTokenId(_tokenId, _sig);
        if (!success) {
            revert("Invalid req");
        }
        
        Entity memory _entity = Entity(_genes, block.timestamp);
        entitys[_tokenId] = _entity;
        _mint(_owner, _tokenId);
        emit RebirthEvent(_tokenId, _owner, _genes);
    }

    function upgrade(uint256 _tokenId, uint256 _genes, bytes calldata _sig)
        external
    {
        bool success;
        address signer;
        (success, signer) = verifyTokenId(_tokenId, _sig);
        if (!success) {
            revert("Invalid req");
        }

        Entity storage _entity = entitys[_tokenId];
        _entity.genes = _genes;
        _entity.bornAt = block.timestamp;
        emit UpgradeEvent(_tokenId, _genes);

    }

    function retire(uint256 _tokenId, bytes calldata _sig)
        external
    {
        bool success;
        address signer;

        (success, signer) = verifyTokenId(_tokenId, _sig);

        if (!success) {
            revert("Invalid req");
        }


        require(entitys[_tokenId].bornAt != 0, "Upgrade: token nonexistent");
        delete(entitys[_tokenId]);
        _burn(_tokenId);
        emit RetiredEvent(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {

        string memory baseURI = contractURI;
        string memory baseURI2 = contractURI2;
        Entity memory _entity = entitys[_tokenId];
        if(_entity.bornAt != 0) {
            return string(abi.encodePacked(baseURI2, _tokenId.toString(), ".json"));
        }
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _returnDust() private {
        uint256 _remainingETH = remainingETH;
        assembly {
            if gt(_remainingETH, 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    _remainingETH,
                    0,
                    0,
                    0,
                    0
                )
                if iszero(callStatus) {
                  revert(0, 0)
                }
            }
        }
    }

      /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}