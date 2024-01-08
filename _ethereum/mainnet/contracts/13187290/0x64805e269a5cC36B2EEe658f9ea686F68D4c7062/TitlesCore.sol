//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./TitlesDraw.sol";

uint256 constant MAX_PROJECTS_PER_TITLE = 10;
uint256 constant PRICE_CREATE = 10**18;

struct Title { 
   string name;
   address creator;
   uint256 claims;
   string fColor;
   string bColor;
   uint256 price;
}

contract TitlesCore is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address public drawContract; 

    uint256 public totalTitles = 0;
    uint256 public totalTokens = 0;

    mapping(uint256 => address[]) public titleAddresses;
    mapping(uint256 => uint256[]) public titleMinAssets;
    mapping(uint256 => Title) public titles;

    mapping(uint256 => uint256) public tokenTitle;

    mapping(string => bool) private usedNames;
    mapping(string => uint256) public namesToIds;

    event TitleCreated(string name, address indexed creator);
    event TitleClaimed(uint256 indexed titleId, address indexed creator);

    mapping(address => uint256) public credit;
    event Withdrawn(address payee, uint256 payment);

    constructor(address ownerAddress, address _drawContract) ERC721("CryptoTitles", "CTL")  {
        transferOwnership(ownerAddress);
        drawContract = _drawContract;
    }

    function addTitle(string memory _name, address[] memory _projectAddresses, uint256[] memory _minAssets, string memory _fColor, string memory _bColor, uint256 _price) payable public {
        require(_projectAddresses.length <= MAX_PROJECTS_PER_TITLE && _projectAddresses.length > 0, "Max Projects reached or invalid projects");
        require(_projectAddresses.length == _minAssets.length, "Incomplete input");
        require(TitlesDraw(drawContract).validateName(_name), "Invalid name");
        require(!usedNames[_name], "Name used");
        require (msg.value == PRICE_CREATE, "Insuficient eth");
        require(TitlesDraw(drawContract).validateColor(_fColor) && TitlesDraw(drawContract).validateColor(_bColor), "Invalid color");
                
        totalTitles++;

        for (uint i=0; i<_minAssets.length; i++) {
            require(_minAssets[i] >=1, "At least 1");
        }

        for (uint i=0; i<_projectAddresses.length; i++) {
            ERC721Enumerable(_projectAddresses[i]).balanceOf(msg.sender); //will fail if balanceOf is not there
            ERC721Enumerable(_projectAddresses[i]).name(); //will fail if name is not there
        }

        titleAddresses[totalTitles] = _projectAddresses;
        titleMinAssets[totalTitles] = _minAssets;
        titles[totalTitles] = Title({name: _name, creator:msg.sender, claims: 0, fColor: _fColor, bColor: _bColor, price: _price});

        usedNames[_name] = true;
        namesToIds[_name] = totalTitles;

        credit[owner()] += msg.value;

        emit TitleCreated(_name, msg.sender);
    }

    function claim(uint256 _titleId) payable public {
        require(verifyTitle(_titleId, msg.sender), "Missing tokens");
        require (msg.value == titles[_titleId].price, "Insuficient eth");
        totalTokens++;
        titles[_titleId].claims++;

        tokenTitle[totalTokens] = _titleId;
        _safeMint(msg.sender, totalTokens);

        uint256 amount = msg.value/2;
        credit[titles[_titleId].creator] += amount;
        credit[owner()] += amount;

        emit TitleClaimed(_titleId, msg.sender);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        uint256 title = tokenTitle[_tokenId];
        Title memory titleProps = titles[title];

        string memory svgOut = TitlesDraw(drawContract).getSvg(titleProps.name, titleProps.fColor, titleProps.bColor, verifyTitle(title, ownerOf(_tokenId)));
        
        string memory jsonOut = Base64.encode(bytes(string(abi.encodePacked('{"name": "', titleProps.name, '", "description": "Title type #' , title.toString() ,'. Requirements are ', getRequirements(title), '", "image": "', svgOut , '"}'))));

        return string(abi.encodePacked('data:application/json;base64,', jsonOut));
    }

    function getRequirements(uint256 title) public view returns (string memory) {
        return TitlesDraw(drawContract).getRequirements(titleAddresses[title], titleMinAssets[title]);
    }

    function verifyTitle(uint256 _titleId, address _account) public view returns (bool) {
        require(_titleId <= totalTitles, "Title id not found"); 
        require(titleAddresses[_titleId].length > 0, "Title id not found");
        for (uint i=0; i<titleAddresses[_titleId].length; i++) {
            if(IERC721(titleAddresses[_titleId][i]).balanceOf(_account) < titleMinAssets[_titleId][i])
                return false;
        }
        return true;
    }

    //hack to work with collab.land as ERC1155
    function balanceOf(address account, uint256 id2) public view virtual returns (uint256) { 
        require(account != address(0), "ERC721: balance query for the zero address");
        if(verifyTitle(id2, account))
            return 1;
        return 0;
    }

    function withdrawCredit() public { 
        require(credit[msg.sender] > 0, "no credit to withdraw");
        uint256 payment = credit[msg.sender];

        credit[msg.sender] = 0;

        payable(msg.sender).transfer(payment);

        emit Withdrawn(msg.sender, payment);
        
    }

    function setDrawContract(address _drawContract) public onlyOwner {
        drawContract = _drawContract;
    }
}
