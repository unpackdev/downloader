// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./Ownable.sol";
import "./IBuilderMaterial.sol";
import "./IPasscard.sol";
import "./ERC721A.sol";


contract PoorLandMetaverse is ERC721A, Ownable {

    /// @dev Library
    using Strings for uint256;

    event BuildEvent(address indexed builder, bytes buildingInfo, uint256 buildTime);

    /// @dev mapIndex=>bytes((i32 x1, i32 y1), (x2,y2))
    mapping(int32=>bytes) private _mapInfo;

    /// @dev mapIndex=>existedBuilding[]
    mapping(int32=>uint256[]) private _buildingBelong;

    // /// @dev ID=>(u256 type, i32 mx, i32 my)
    mapping(uint256=>bytes) private _buildingInfo;

    // map=> build type=>(1=disable,0=enable)
    mapping(int32=>mapping(uint256=>uint256)) private _disabledBuilding;

    bool private _passcardRequired = false;

    address private _passcard;

    string private _base_URI = "https://gateway.poorland.io/";

    string private _path = "ipfs/QmYYHeMkuZAoPpBpijnpwADcdfRXaa7jpwcnpW71uT8NDF/";

    address public constant _poorlandMaterialContract = 0x045737619bb0FE286FFB8c9C81117bC4aB5C997f;

    bool private _building = true;

    /// @notice legal map indexs
    uint[] private _mapIndexs;

    mapping(int32=>uint256) private _mapBuildFee;

    /// extra NFT type and build price 
    /// type=>(poorlandmaterial, width, height)
    mapping(uint256=>bytes) private _typeExtension;

    constructor() ERC721A("PoorLandMetaverse", "PLM") {      
        // map index
        int32 x1 = -112;
        int32 y1 = 112;
        int32 x2 = 112;
        int32 y2 = -112;
        bytes memory mapSize = abi.encode(x1,y1,x2,y2);
        _mapInfo[1] = mapSize;
        _disabledBuilding[1][41] = 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _base_URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return bytes(_base_URI).length > 0 ? string(abi.encodePacked(_base_URI, _path, tokenId.toString(), ".json")) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function build(int32 mapIndex, uint256 nftType, int32 x, int32 y) external payable {
        require(_building, "not start yet");
        // type must be supported.
        require(_typeSupport(nftType), "not support");
        require(_mapExists(mapIndex), "not exist");
        require(_availableToBuild(mapIndex, nftType), "can't build now");
        require(_passcardRequirement(msg.sender, nftType), "passcard required");
        require(_noHit(mapIndex, nftType, x, y), "hit another area");

        //check balance
        uint256 buildFee = _mapBuildFee[mapIndex];
        if (buildFee > 0) {
            require (msg.value >= buildFee, "build fee is not enough" );
        }
            
        uint256 requiredMaterial = calculatePayment(nftType);
        // is balance enough
        uint256 ownedMaterial = IERC1155(_poorlandMaterialContract).balanceOf(msg.sender, 0);
        require(ownedMaterial >= requiredMaterial, "Fragment is not enough");

        // spend material and burn
        IBuilderMaterial(_poorlandMaterialContract).spendMaterialToBuild(msg.sender, requiredMaterial);
        uint256 tokenID = _startTokenId() + _totalMinted();
        mintTo(msg.sender, 1);
        bytes memory buildInfo = abi.encode(mapIndex, tokenID, nftType, x, y);
        bytes memory building = abi.encode(nftType, x, y);
        _buildingInfo[tokenID] = building;
        _buildingBelong[mapIndex].push(tokenID);
        emit BuildEvent(msg.sender, buildInfo, block.timestamp);

    }

    function _passcardRequirement(address builder, uint256 buildType) private returns (bool) {
        if (_passcard == address(0) || _passcardRequired == false) {
            return true;
        }
        return IPasscard(_passcard).qualified(builder, buildType);
    }

    function calculatePayment(uint nftType) public view returns(uint256 poorlandMaterial) {
        if (nftType == 11) {
            return 10;
        }
        if (nftType == 21) {
            return 100;
        }
        if (nftType == 31) {
            return 1000;
        }
        if (nftType == 41) {
            return 10000;
        }
        (uint256 material, int32 bw, int32 bh) = abi.decode(_typeExtension[nftType], (uint256, int32, int32));
        return material;

    }

    function _typeSupport(uint nftType) public view returns(bool) {
        
        if (nftType == 11 || nftType == 21 || nftType == 31 || nftType == 41) {return true;}
        // extension
        return _typeExtension[nftType].length > 0;

    }

    /// @dev map 1 is default
    function _mapExists(int32 mapIndex) public view returns(bool) {
        if (mapIndex == 1) {
            return true;
        }
        return _mapInfo[mapIndex].length > 0;
    }  

    function boxHit(int32 x11, int32 y11, int32 w1, int32 h1, int32 x21, int32 y21, int32 w2, int32 h2) internal pure {
        int32 x12 = x11 + w1 - 1;
        int32 y12 = y11 - h1 + 1;
        int32 x22 = x21 + w2 - 1;
        int32 y22 = y21 - h2 + 1;
        if (x11 >= x21 && x11 <= x22 && y11 <= y21 && y11 >= y22) {
            require (false, "left top hit");
        }

        if (x12 >= x21 && x12 <= x22 && y11 <= y21 && y11 >= y22) {
            require (false, "right top hit");
        }

        if (x11 >= x21 && x11 <= x22 && y12 <= y21 && y12 >= y22) {
            require (false, "left bottom hit");
        }

        if (x12 >= x21 && x12 <= x22 && y12 <= y21 && y12 >= y22) {
            require (false, "right bottom hit");
        }
    }

    function _noHit(int32 mapIndex, uint256 nftType, int32 x, int32 y) internal view returns (bool) {
        require(_mapBorderNoHit(mapIndex, nftType, x, y), "hit border");
        uint256[] memory mapBuildings = _buildingBelong[mapIndex];
        (int32 w, int32 h) = _buildingSize(nftType);
        for(uint256 i=0; i<mapBuildings.length; i++) {
            (uint256 buildingType, int32 x1, int32 y1)  = abi.decode(_buildingInfo[mapBuildings[i]], (uint256, int32, int32));
            (int32 w1, int32 h1) =_buildingSize(buildingType);
            boxHit(x, y, w, h , x1, y1, w1, h1);
        }
        return true;
    }
    
    function _mapBorderNoHit(int32 mapIndex, uint256 nftType, int32 x, int32 y) internal view returns (bool) {
        (int32 mx1, int32 my1, int32 mx2, int32 my2) = abi.decode(_mapInfo[mapIndex], (int32, int32, int32, int32));
        (int32 w, int32 h) = _buildingSize(nftType);
        require ( x >= mx1 && x <= mx2, "x out");
        require ( y <= my1 && y >= my2, "y out");
        require ( x + w - 1 <= mx2, "x + w - 1 border out");
        require ( y - h + 1>= my2, "y - h + 1 border out");
        return true;
    }

    function _availableToBuild(int32 mapIndex_, uint256 nftType) public view returns (bool) {
        if (_disabledBuilding[mapIndex_][nftType] == 0) {
            return true;
        }
        return false;
    }

    function _buildingSize(uint256 nftType) public view returns (int32 width, int32 height) {
        if (nftType == 11) {return (3,3);}
        if (nftType == 21) {return (10,10);}
        if (nftType == 31) {return (32,32);}
        if (nftType == 41) {return (100,100);}
        // extension
        if(_typeSupport(nftType)){ 
            (uint256 material, int32 bw, int32 bh) = abi.decode(_typeExtension[nftType], (uint256, int32, int32));
            return (bw, bh);
        }
    }

    function minted(address addr) external view returns(uint256) {
        return _numberMinted(addr);
    }

    function listMyNFT(address owner) external view returns (uint256[] memory tokens) {
        uint256 owned = balanceOf(owner);
        tokens = new uint256[](owned);
        uint256 start = 0;
        for (uint i=0; i<totalSupply(); i++) {
            if (ownerOf(i) == owner) {
                tokens[start] = i;
                start ++;
            }
        }
    }

    function getMapInfo(int32 mapIndex) external view returns(int32 x1, int32 y1, int32 x2, int32 y2) {
        (x1,y1,x2,y2) = abi.decode(_mapInfo[mapIndex], (int32, int32, int32, int32));
    }

    /// @dev mint function
    function mintTo(address purchaseUser, uint256 amount) private {
        _safeMint(purchaseUser, amount);
    }

    function updatePasscard(address contract_, bool require_) external onlyOwner {
        _passcard = contract_;
        _passcardRequired = require_;
    }

    function updateMapBuildFee(int32 mapIndex_, uint256 buildFee_) external onlyOwner {
        _mapBuildFee[mapIndex_] = buildFee_;
    }

    function updateMapIndex(int32 mapIndex_, int32 x1, int32 y1, int32 x2, int32 y2) external onlyOwner {
        _mapInfo[mapIndex_] = abi.encode(x1,y1,x2,y2);
    }

    function updateBuildType(uint256 nftType, uint256 fragmentNeeded, int32 w, int32 h) external onlyOwner {
        _typeExtension[nftType] = abi.encode(fragmentNeeded, w, h);
    }

    function updateURI(string memory uri_) external onlyOwner {
        _base_URI = uri_;
    }

    function updatePath(string memory path_) external onlyOwner {
        _path = path_;
    }

    function updateBuildStatus(bool build_) external onlyOwner {
        _building = build_;
    }

    function setBuildingDisable(int32 mapIndex, uint256 nftType, uint256 flag) external onlyOwner {
        _disabledBuilding[mapIndex][nftType] = flag;
    }

    function withdrawTo(address targetAddress) external onlyOwner {
        payable(targetAddress).transfer(address(this).balance);
    }

    function withdrawLimit(address targetAddress, uint256 amount) external onlyOwner {
        payable(targetAddress).transfer(amount);
    }
}