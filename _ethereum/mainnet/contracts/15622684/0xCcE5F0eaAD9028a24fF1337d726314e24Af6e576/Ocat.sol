// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./SignatureChecker.sol";
import "./ERC721A.sol";

error InvalidSignature();

contract Ocat is Ownable, ERC721A {    
    struct GlobalConfigItem {
        uint256 totalNum;
        uint256 StartTime;
        uint256 EndTime;
        bool isOpen;
        bool isOnly;
    }
    uint256 MAX_TOTAL_SUPPLY = 10000;
    uint256 nowResidue = 0;
    uint256 oldIndex = 1;
    address[] whiteListAddress;
    uint256 public nowPage = 0;    
    address public repoAddress = 0xeF42dd48940E6E352410f1Fd62b17267A8CFAF33;

    mapping (uint256 => bool) pageActive;
    mapping (uint256 => string) _baseTokenURI;
    mapping (uint256 => GlobalConfigItem) globalConfig;
    mapping (uint256 => address) authority;

    constructor() ERC721A("Ocat Token", "Ocat") {
        authority[1] = 0x3fFC0C2cF1E7D25109471BAE8705475181d4031b;
        authority[2] = 0x4DA3c533e1565057a69da9eab0e9255913cc7aAB;
        authority[3] = 0x422002dd3714C7DadFd33959Eb9C23E1764b18F8;
        authority[4] = 0x0A54E90bDDF21f881E7c407a97F3d9c848e96306;
    }

    /**
     * @dev limit another contract
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**For Ocat global configuration*/
    function _setGlobalConfig( uint256 PageID, GlobalConfigItem memory configData ) public onlyOwner {
        require(PageID > 0 && configData.totalNum > 0,"Config Error");
        require(pageActive[PageID] == false,"The PageID has started");
        require(configData.EndTime > configData.StartTime,"Incorrect configuration format");

        globalConfig[PageID] = configData;
    }

    /**From here on*/
    function startNewPage(uint256 PageID) public onlyOwner {
        require(nowPage != PageID && PageID > nowPage,"PageID NEQ now Page");
        GlobalConfigItem memory configData = globalConfig[PageID];
        require(
            block.timestamp < configData.EndTime,
            "Config Missing Or Error"
        );
        require(
            totalSupply() + configData.totalNum <= MAX_TOTAL_SUPPLY,
            "More MAX totalSupply"
        );

        if(nowPage > 0){
            pageActive[nowPage] = false;
        }
        pageActive[PageID] = true;
        if(nowResidue > 0){
            for (uint256 i = 0; i < nowResidue; i++) {
                uint256 tokenID = getTokenID();
                _safeMint(repoAddress, tokenID);
            }
        }
        nowPage = PageID;
        nowResidue = configData.totalNum;
    }

    /**airdrop mint And Provide lock-up time*/
    function airdropMint(address[] memory tos) external onlyOwner {
        require(
            pageActive[nowPage],
            "This activity hasn't started yet"
        );

        uint256 quantity = tos.length;
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenID = getTokenID();
            _safeMint(tos[i], tokenID);
        }
    }

    function isMintOn() public view returns (bool) {
        return
            pageActive[nowPage] &&
            globalConfig[nowPage].StartTime <= block.timestamp &&
            globalConfig[nowPage].EndTime > block.timestamp;
    }

    function OcatMint(uint256 salt, bytes calldata signature) external callerIsUser {
        require(isMintOn(),"Not Meet Mint Time");
        require(nowResidue >= 1,"Not enough for mint");

        if(globalConfig[nowPage].isOpen && globalConfig[nowPage].isOnly){
            OcatOpenOnlyMint();
        }
        if(globalConfig[nowPage].isOpen == false && globalConfig[nowPage].isOnly == false){
            OcatWhiteListMint(salt,signature);
        }
        uint256 tokenID = getTokenID();
        _safeMint(msg.sender, tokenID);
        nowResidue --;
    }
    
    function OcatWhiteListMint(uint256 salt, bytes calldata signature) view private {
        bytes32 HashData = keccak256(abi.encodePacked(msg.sender, salt));
        if (
            !SignatureChecker.isValidSignatureNow( authority[nowPage], HashData, signature )
        ) {
            revert InvalidSignature();
        }
    }

    function OcatOpenOnlyMint() private {
        require(
            allowWhiteListMint(msg.sender),
            "Must Only One"
        );

        whiteListAddress.push(msg.sender);
    }

    function getNowPageConfig(uint256 page) view public returns(uint256,uint256,uint256,uint256){
        if(page == 0){page = nowPage;}
        uint256 ResidueNum = 0;
        if(page > nowPage){
            ResidueNum = globalConfig[page].totalNum;
        }else if(page ==  nowPage){
            ResidueNum = nowResidue;
        }
        return (ResidueNum,globalConfig[page].totalNum,globalConfig[page].StartTime,globalConfig[page].EndTime);
    }


    /**
     *  @dev NFT BaseURI
     */
    function _baseURI(uint256 tokenId) internal view virtual override returns (string memory) {
        uint256 pageIndex = (tokenId / 10000);
        return _baseTokenURI[pageIndex];
    }

    function setBaseURI(uint256 PageID, string calldata baseURI) external onlyOwner {
        _baseTokenURI[PageID] = baseURI;
    }

    function allowWhiteListMint(address checkAddr) private view returns(bool){
        for(uint i=0;i<whiteListAddress.length;i++){
            if(checkAddr == whiteListAddress[i]){
                return false;
            }
        }
        return true;
    }

    function getTokenID() private returns (uint256) {
        uint256 oldPage = (oldIndex / 10000);
        if(oldPage < nowPage){
            oldIndex = (nowPage * 10000);            
        }else{
            oldIndex++;
        }        
        return oldIndex;
    }
}