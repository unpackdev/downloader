// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;



/**  
██╗░░░██╗░█████╗░██╗░░░██╗██╗░░░░░████████╗
██║░░░██║██╔══██╗██║░░░██║██║░░░░░╚══██╔══╝
╚██╗░██╔╝███████║██║░░░██║██║░░░░░░░░██║░░░
░╚████╔╝░██╔══██║██║░░░██║██║░░░░░░░░██║░░░
░░╚██╔╝░░██║░░██║╚██████╔╝███████╗░░░██║░░░
░░░╚═╝░░░╚═╝░░╚═╝░╚═════╝░╚══════╝░░░╚═╝░
**/




import "./Counters.sol";
import "./AbstractERC1155Factory.sol";

/*
* @title ERC1155 tokens for Vault memberships
* Created by Davo#9627
*
*/
contract Vault is AbstractERC1155Factory  {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 


    mapping(uint256 => bool) private isSaleOpen;

    mapping(uint256 => Pass) public Passes;

    event Purchased(uint indexed index, address indexed account, uint amount);

    struct Pass {
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPurchaseTx;
        uint256 purchased;
        string ipfsMetadataHash;
    }

    constructor(
        string memory _name, 
        string memory _symbol  
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;
    }

    /**
    * @notice adds a new Pass
    * 
    * @param _mintPrice mint price in wei
    * @param _maxSupply maximum total supply
    * @param _ipfsMetadataHash the ipfs hash for Pass metadata
    */
    function addPass(
        uint256  _mintPrice, 
        uint256 _maxSupply,  
        uint256 _maxPurchaseTx,        
        string memory _ipfsMetadataHash
    ) public onlyOwner {
        Pass storage p = Passes[counter.current()];
        p.mintPrice = _mintPrice;
        p.maxSupply = _maxSupply;
        p.maxPurchaseTx = _maxPurchaseTx;                                        
        p.ipfsMetadataHash = _ipfsMetadataHash;

        counter.increment();
    }    

    /**
    * @notice edit an existing Pass
    * 
    * @param _mintPrice mint price in wei
    * @param _maxSupply the maximum supply
    * @param _ipfsMetadataHash the ipfs hash for Pass metadata
    * @param _PassIndex the Pass id to change
    */
    function editPass(
        uint256  _mintPrice,
        uint256 _maxSupply, 
        uint256 _maxPurchaseTx,        
        string memory _ipfsMetadataHash,
        uint256 _PassIndex
    ) external onlyOwner {
        require(exists(_PassIndex), "EditPass: Pass does not exist");

        Passes[_PassIndex].mintPrice = _mintPrice;
        Passes[_PassIndex].maxSupply = _maxSupply;     
        Passes[_PassIndex].maxPurchaseTx = _maxPurchaseTx;                       
        Passes[_PassIndex].ipfsMetadataHash = _ipfsMetadataHash;    
    }    

    /**
    * @notice mint Pass tokens
    * 
    * @param PassID the Pass id to mint
    * @param amount the amount of tokens to mint
    */
    function ownerMint(uint256 PassID, uint256 amount, address to) external onlyOwner {
        require(exists(PassID), "Mint: Pass does not exist");

        _mint(to, PassID, amount, "");
    }


    /**
    * @notice open Pass sale
    * 
    * @param PassIds the Pass ids to close the sale for
    */
    function openSale(uint256[] calldata PassIds) external onlyOwner {
        uint256 count = PassIds.length;

        for (uint256 i; i < count; i++) {
            require(exists(PassIds[i]), "Open sale: Pass does not exist");

            isSaleOpen[PassIds[i]] = true;
        }
    }




    /**
    * @notice close Pass sale
    * 
    * @param PassIds the Pass ids to close the sale for
    */
    function closeSale(uint256[] calldata PassIds) external onlyOwner {
        uint256 count = PassIds.length;

        for (uint256 i; i < count; i++) {
            require(exists(PassIds[i]), "Close sale: Pass does not exist");

            isSaleOpen[PassIds[i]] = false;
        }
    }


    /**
    * @notice purchase Pass tokens
    * 
    * @param PassID the Pass id to purchase
    * @param amount the amount of tokens to purchase
    */
    function mint(uint256 PassID, uint256 amount) external payable {
        require(isSaleOpen[PassID], "Purchase: sale is not open");
        require(amount <= Passes[PassID].maxPurchaseTx, "Purchase: Max purchase per tx exceeded");                
        require(totalSupply(PassID) + amount <= Passes[PassID].maxSupply, "Purchase: Max total supply reached");
        require(msg.value == amount * Passes[PassID].mintPrice, "Purchase: Incorrect payment"); 

        Passes[PassID].purchased += amount;

        _mint(msg.sender, PassID, amount, "");

        emit Purchased(PassID, msg.sender, amount);
    }



    /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * 
     */
    function withdraw() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        payable(0xb72f1Fb3cB41D9143BbF759EA8493EBF47F5245F).transfer(currentBalance * 20/100);
        payable(0x5Bd33D400a9354605D91D527AdD0b148608f3424).transfer(currentBalance * 80/100);
  }

    /**
    * @notice return total supply for all existing Passs
    */
    function totalSupplyAll() external view returns (uint[] memory) {
        uint[] memory result = new uint[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }

    /**
    * @notice indicates whether any token exist with a given id, or not
    */
    function exists(uint256 id) public view override returns (bool) {
        return Passes[id].maxSupply > 0;
    }    

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _id the Pass id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), Passes[_id].ipfsMetadataHash));
    }    
}
