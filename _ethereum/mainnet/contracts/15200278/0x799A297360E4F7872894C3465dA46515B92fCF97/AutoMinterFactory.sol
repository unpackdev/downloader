// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./AutoMinterERC721.sol";
import "./AutoMinterERC721A.sol";
import "./OwnableUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract AutoMinterFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable
{
    address erc721Implementation;
    uint256 public fee;
    address erc721AImplementation;

    event ContractDeployed(string indexed appIdIndex, string appId, address indexed erc721Implementation, address author);
    
    function initialize() public initializer  {
        __Ownable_init_unchained();
        __UUPSUpgradeable_init();
        erc721Implementation = address(new AutoMinterERC721());
    }
    
    /* Create an NFT Collection and pay the fee */
    function create(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory appId_,
        uint256 mintFee_,
        uint256 size_,
        bool mintSelectionEnabled_,
        bool mintRandomEnabled_,
        address whiteListSignerAddress_,
        uint256 mintLimit_,
        uint256 royaltyBasis_,
        string memory placeholderImage_) payable public
    {
        require(msg.value >= fee, 'Must pass the correct fee to the contract');
        
        address payable clone = payable(ClonesUpgradeable.clone(erc721Implementation));

        AutoMinterERC721(clone).initialize(name_,
            symbol_,
            baseURI_,
            msg.sender,
            mintFee_,
            size_,
            mintSelectionEnabled_,
            mintRandomEnabled_,
            whiteListSignerAddress_,
            mintLimit_,
            royaltyBasis_,
            placeholderImage_
        );
        
        emit ContractDeployed(appId_, appId_, clone, msg.sender);
    }
    
    /* Create an NFT Collection and pay the fee */
    function createConsecutive(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory appId_,
        uint256 mintFee_,
        uint256 size_,
        address whiteListSignerAddress_,
        uint256 mintLimit_,
        uint256 royaltyBasis_,
        string memory placeholderImage_) payable public
    {
        require(msg.value >= fee, 'Must pass the correct fee to the contract');
        
        address payable clone = payable(ClonesUpgradeable.clone(erc721AImplementation));

        AutoMinterERC721A(clone).initialize(name_,
            symbol_,
            baseURI_,
            msg.sender,
            mintFee_,
            size_,
            whiteListSignerAddress_,
            mintLimit_,
            royaltyBasis_,
            placeholderImage_
        );
        
        emit ContractDeployed(appId_, appId_, clone, msg.sender);
    }
    
    /* Change the fee charged for creating contracts */
    function changeFee(uint256 newFee) onlyOwner() public {
        fee = newFee;
    }

    /* add an existing contract the the factory collection so it can be tracked */
    function addExistingCollection(address collectionAddress, address owner, string memory appId) onlyOwner() public{
        emit ContractDeployed(appId, appId, collectionAddress, owner);
    }
    
    /* Transfer balance of this contract to an account */
    function transferBalance(address payable to, uint256 ammount) onlyOwner() public{
        require(address(this).balance >= ammount);
        to.transfer(ammount);
    }
    
    function version() external pure returns (string memory)
    {
        return "1.0.5";
    }

    function setERC721Implementation(address payable implementationContract) onlyOwner() public {
        erc721Implementation = implementationContract;
    }

    function setERC721AImplementation(address payable implementationContract) onlyOwner() public {
        erc721AImplementation = implementationContract;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner() {}
}