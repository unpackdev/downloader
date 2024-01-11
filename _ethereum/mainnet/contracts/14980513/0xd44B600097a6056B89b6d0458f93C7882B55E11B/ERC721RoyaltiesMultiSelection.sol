//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
//Ownable is needed to setup sales royalties on Open Sea
//if you are the owner of the contract you can configure sales Royalties in the Open Sea website

//the rarible dependency files are needed to setup sales royalties on Rarible
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./SelectionContract.sol";

//give your contract a name
contract ERC721RoyaltiesMultiSelection is
    ERC721Enumerable,
    SelectionContract,
    RoyaltiesV2Impl
{
    using Strings for uint256;

    //configuration
    string baseURI;

    //set the cost to mint each NFT
    uint256 public cost = 0.01 ether;

    //set the maximum number an address can mint at a time
    uint256 public maxMintAmount = 1;

    //is the contract paused from minting an NFT
    bool public paused = false;

    //are the NFT's revealed (viewable)? If true users can see the NFTs.
    //if false everyone sees a reveal picture
    bool public revealed = true;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint96 public RoyaltiesPercentageBasisPoints = 1000;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        selectionSupplies.push(SelectionLib.Selection("Amsterdam", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Atlanta", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Barcelona", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Berlin", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Boston", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Buenos Aires", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Chicago", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Dublin", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Hong Kong", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Lisbon", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("London", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Los Angeles", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Madrid", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Mexico City", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Miami", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Milan", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Montreal", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("New York", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Paris", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Prague", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Rio de Janeiro", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Rome", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("San Francisco", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Toronto", 750, 0, 0.01 ether));
        selectionSupplies.push(SelectionLib.Selection("Vancouver", 750, 0, 0.01 ether));
    }

    //internal function for base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    //function allows you to mint an NFT token
    function mint(uint256 _mintAmount, string memory selectionName)
        public
        payable
    {
        SelectionLib.Selection memory selection = getSelection(selectionName);
        uint256 supply = totalSupply();
        uint256 selectionIndex;

        for (uint256 index = 0; index < selectionSupplies.length; index++) {
            SelectionLib.Selection memory actualSelection = selectionSupplies[index];
            if (
                keccak256(abi.encodePacked(selectionName)) ==
                keccak256(abi.encodePacked(actualSelection.name))
            ) selectionIndex = index;
        }

        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(selection.totalSupply + _mintAmount <= selection.maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= cost * selection.mintCost);
        }

        address payable own = payable(owner());

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 newId = supply + i;
            uint256 newSelectionId = selection.totalSupply + i;
            _safeMint(msg.sender, newId);
            LibPart.Part[] memory _royalties = new LibPart.Part[](1);
            _royalties[0].value = RoyaltiesPercentageBasisPoints;
            _royalties[0].account = own;
            _saveRoyalties(newId, _royalties);
            selectionsNFT.push(
                SelectionLib.NFTSelection(newId, selectionIndex, newSelectionId)
            );
            selectionSupplies[selectionIndex] = SelectionLib.Selection(
                selection.name,
                selection.maxSupply,
                newSelectionId,
                selection.mintCost
            );
        }
        own.transfer(msg.value);
    }

    //function returns the owner
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    //input a NFT token ID and get the IPFS URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = getNFTSelection(tokenId, _baseURI());
        return currentBaseURI;
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    //set the cost of an NFT
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    //set the max amount an address can mint
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    //set the base URI on IPFS
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //pause the contract and do not allow any more minting
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    //configure royalties for Rariable
    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        //use the same royalties that were saved for Rariable
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}
