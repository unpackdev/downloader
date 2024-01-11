//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";

contract Imagine is ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {

    using Strings for uint256;

    //var
    uint256 MAX_SUPPLY = 50;
    uint256 MaxPerMint = 3;
    uint256 public ReImaginationCost = 0.02 ether;
    bool public paused = false;
    bool public isActive = false;
    string public URI;
    string public RenderingURI;
    string private uriSuffix = ".json";
    bool public ImaginationBlock;
    mapping(address => uint256) public CanMint;
    mapping(uint256 => uint256) public ImaginedCount; //how many times it was re-imagined
    mapping(uint256 => string) public Imagination; //the imagination context
    mapping(uint256 => bool) public Rendering; //is it being imagined?

    //only approved operators

    address[] public OperatorList = [0x1E0049783F008A0085193E00003D00cd54003c71,
                                     0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e,
                                     0xF849de01B080aDC3A814FaBE1E2087475cF2E354,
                                     0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be
                                    ];
    mapping (address => bool) public ApprovedAddr; 

    constructor(string memory _RenderingURI,address _RoyaltyReceiver, uint96 _royaltyAmount)  ERC721("Imagine", "IMGN")  {
        RenderingURI = _RenderingURI;
        setRoyaltyInfo(_RoyaltyReceiver,_royaltyAmount);
        _ApplyApprover();
    }

   
    modifier IsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    //Metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!Rendering[tokenId]) {
            return RenderingURI;
        }
        return string(abi.encodePacked(URI, Strings.toString(tokenId), uriSuffix));
    }

    /*function toggleReveal(string memory updatedURI) public onlyOwner {
        REVEAL = !REVEAL;
        URI = updatedURI;
    }*/

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        URI = _newBaseURI;
    }

    function setSupply(uint256 NewSupply) public onlyOwner {
        MAX_SUPPLY = NewSupply;
    }

    function setRenderingURI(string memory _newRenderingURI) public onlyOwner {
        RenderingURI = _newRenderingURI;

    }


    function ApplyImagination(uint256 token, string memory _imagination) external payable {
        require(msg.value == ReImaginationCost,"not suffeciant fund");
        require(_exists(token),"nonexistent token");
        require(ownerOf(token) == msg.sender,"not token owner");
        require(!ImaginationBlock,"Can not change now");
        ImaginedCount[token] = ImaginedCount[token]++;
        Imagination[token] = _imagination;
    }

    function DoneRendering(uint256[] calldata tokenid) public onlyOwner{
        for(uint256 i = 0; i< tokenid.length;i++)
        Rendering[tokenid[i]] = true;
    }
    //General

    function SetImagination(bool CanImagine) public onlyOwner {
        ImaginationBlock = CanImagine;
    }

    function setPause(bool ispaused) public onlyOwner {
        paused = ispaused;
    }

    function setActive() public onlyOwner {
        isActive = !isActive;
    }

    function whitelisAddress(
        address[] calldata _users,
        uint256[] calldata _amount
    ) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            CanMint[_users[i]] = _amount[i];
        }
    }

    //AL mint


    function ImagineSomething(string memory _WhatYouWant) public IsUser nonReentrant {
        uint256 supply = totalSupply();
        uint256 _mintAmount = CanMint[msg.sender];
        require(!paused, "the contract is paused");
        require(supply + _mintAmount <= MAX_SUPPLY, "max supply reached");
        require(CanMint[msg.sender] > 0, "Not Whitelisted");
        //require(Whitelisted[msg.sender] >= _mintAmount, "Amount is higher than available claim");
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
        supply++;
        _mint(msg.sender, supply);
        Imagination[supply] = _WhatYouWant;
        }
        CanMint[msg.sender] = 0;

    }



    //Mint

    function mint(uint256 _mintAmount,string memory _WhatYouWant) public IsUser nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "the contract is paused");
        require((totalSupply() + _mintAmount) <= MAX_SUPPLY, "max supply reached");
        require(isActive, "Public sale is not active");
        require(_mintAmount <= MaxPerMint, "Max mint per wallet reached");
        for (uint256 i = 1; i <= _mintAmount; i++) {
        supply++;
        _mint(msg.sender, supply);
        Imagination[supply] = _WhatYouWant;
        }
    }

    //owner mint
    function OwnerMint(address to, uint256 amount) public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= amount; i++) {
        supply++;
        _mint(to, supply);
        }
    }

    //approval modification

    function AddApprover(address[] calldata Approver) public onlyOwner {
        for(uint256 i = 0;i< Approver.length;i++){
            if(!ApprovedAddr[Approver[i]]){
            OperatorList.push(Approver[i]);
            }
        }
        _ApplyApprover();
    }

    function _ApplyApprover() internal {
        for(uint256 i = 0;i< OperatorList.length;i++){
            ApprovedAddr[OperatorList[i]] = true;
        }
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        require(ApprovedAddr[operator] == true, "Not approved operator");
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    //royalty 100 is 1%
    
     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
         return super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyAmount) public onlyOwner {
        _setDefaultRoyalty(_receiver,_royaltyAmount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
