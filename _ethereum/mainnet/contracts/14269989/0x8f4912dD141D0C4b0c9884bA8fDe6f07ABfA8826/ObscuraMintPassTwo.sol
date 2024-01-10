//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

         `````                 `````                                                                                                                  
        /NNNNN.               /NNNNN`                                                                                                                 
        /MMMMM.               +MMMMM`                                                                                                                 
        :hhhhh/::::.     -::::sMMMMM`         ``````      ``````````       `...`        ```````     `         `  ````````          ```                
         `````mNNNNs     NNMNFTMMMMM`       ``bddddd.`    mmdddddddd``  .odhyyhdd+`  ``sddddddd/`  gm-       gm/ dmhhhhhhdh+`    `/dddo`              
              mMMMMy     NMMMMMMMMMM`     ``bd-.....bd-`  MM........mm `mM:`` `.oMy  sm/.......sd: gM-       gM+ NM-`````.sMy  `/do...+do`            
              oWAGMI+++++GMMMMMMMMMM`     gm:.      ..gm. MM        MM `NM:.     /:  yM/       `.` gM-       gM+ NM`      :Md /ms.`   `.+mo           
                   /MMMMM`    +MMMMM`     GM.         gM- GMdddddddd:-  -ydhhhs+:.   yM/           gM-       gM+ NM+////+smh. +Ms       +Ms           
                   /MMMMM`    +MMMMM`     GM.         gM- MM::::::::hh    `.-:/ohmh. yM/           gM-       gM+ NMsoooooyNy` +MdsssssssGMs           
              yMMMMs:::::yMMMMMMMMMM`     yh/:      -:yh. MM        MM /h/       sMs yM/       .:` gM/       gM/ NM`      sM+ +Md+++++++GMs           
              gMMMMs     M.OBSCURA.M`       yh/:::::yh.   MM::::::::hh .gM+..``.:CR: oh+:::::::sh: :Nm/.``..oMh` NM`      :My +Ms       +Ms .:.       
         `````mNNNNs     MMMMM'21'MM`         ahhhhh`     hhhhhhhhhh`   `/ydhhhhho.    ohhhhhhh:    .+hdhhhdy/`  hh`      `hy`/h+       /h+ :h+       
        /mmmmm-....`     .....gMMMMM`                                        ``                         ```                                           
        /MMMMM.               +MMMMM`                                                                                                                 
        :mmmmm`               /mmmmm`                                                                                                                 

*/

import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./IERC2981.sol";
import "./console.sol";
import "./recovery.sol";

contract ObscuraMintPassTwo is
    ERC721Enumerable,
    AccessControlEnumerable,
    IERC2981,
    recovery
{
    using Strings for uint256;

    string private _contractURI;
    string public  _defaultCID;

    uint256 private constant DIVIDER = 10**5;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private nextPassId;
    uint256 private defaultRoyalty;
    address private _obscuraAddress;

    mapping(uint256 => uint256) public tokenIdToPass;
    mapping(uint256 => Pass)    public passes;

    mapping(uint256 => bool)    public redeemed;
    mapping(uint256 => address) public minterContracts;


    struct Pass {
        uint256 maxTokens;
        uint256 circulatingPublic;
        uint256 circulatingReserved;
        uint256 platformReserveAmount;
        uint256 price;
        uint256 royalty;
        bool active;
        string name;
        string cid;
    }

    event PassCreatedEvent(address caller, uint256 indexed passId);

    event PassMintedEvent(
        address user,
        uint256 indexed passId,
        uint256 tokenId
    );

    event PlatformReserveMintedEvent(
        address obscuraAddress,
        uint256 indexed passId,
        uint256 firstTokenIdMinted
    );

    event SetSalePublicEvent(
        address caller,
        uint256 indexed passId,
        bool isSalePublic
    );

    event SetPrice(
        uint256 passId,
        uint256 price
    );

    event SetPassRoyaltyEvent(uint256 passId, uint256 royalty);

    event SetPassCIDEvent(uint256 passId, string CID);

    event ObscuraAddressChanged(address oldAddress, address newAddress);

    event MinterAddressChanged(uint256 passId, address _minterContract);

    event TokenRedeemed(uint256 tokenId);

    constructor(address admin, address payable obscuraAddress)
        ERC721("Obscura Mint Pass", "OMP")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _obscuraAddress = obscuraAddress;
        defaultRoyalty = 10;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist");
        uint256 passId = tokenIdToPass[tokenId];
        uint256 _royaltyAmount = (salePrice * passes[passId].royalty) / 100;

        return (_obscuraAddress, _royaltyAmount);
    }

    function isSalePublic(uint256 passId) external view returns (bool active) {
        return passes[passId].active;
    }

    function getPassPrice(uint256 passId)
        external
        view
        returns (uint256 price)
    {
        return passes[passId].price;
    }

    function getPassMaxTokens(uint256 passId)
        external
        view
        returns (uint256 maxTokens)
    {
        return passes[passId].maxTokens;
    }

    function getTokenIdToPass(uint256 tokenId)
        external
        view
        returns (uint256 passId)
    {
        return tokenIdToPass[tokenId];
    }

    function setDefaultCID(string calldata defaultCID)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _defaultCID = defaultCID;
    }


    function setDefaultRoyalty(uint256 royaltyPercent)
        public
        onlyRole(MODERATOR_ROLE)
    {
        defaultRoyalty = royaltyPercent;
    }

    function setPassRoyalty(uint256 passId, uint256 royaltyPercent)
        public
        onlyRole(MODERATOR_ROLE)
    {
        passes[passId].royalty = royaltyPercent;

        emit SetPassRoyaltyEvent(passId, royaltyPercent);
    }

    function setContractURI(string memory contractURI_)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _contractURI = contractURI_;
    }

    function setSalePublic(uint256 passId, bool _isSalePublic)
        external
        onlyRole(MODERATOR_ROLE)
    {
        passes[passId].active = _isSalePublic;

        emit SetSalePublicEvent(msg.sender, passId, _isSalePublic);
    }

    function setPassCID(uint256 passId, string memory cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        passes[passId].cid = cid;

        emit SetPassCIDEvent(passId, cid);
    }

    function setPassPrice(uint256 passId, uint256 price)
        external
        onlyRole(MODERATOR_ROLE)
    {
        passes[passId].price = price;
        emit SetPrice(passId,price);
    }


    function setObscuraAddress(address newObscuraAddress)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _obscuraAddress = payable(newObscuraAddress);

        emit ObscuraAddressChanged(_obscuraAddress, newObscuraAddress);
    }

    function setMinterContract(uint256 passId, address _minterContract)
        external
        onlyRole(MODERATOR_ROLE)
    {
        minterContracts[passId] = _minterContract;

        emit MinterAddressChanged(passId, _minterContract);
    }


    function createPass(
        string memory _name,
        uint256 maxTokens,
        uint256 platformReserveAmount,
        uint256 price,
        string memory cid
    ) external onlyRole(MODERATOR_ROLE) {
        require(maxTokens < DIVIDER, "Cannot exceed 100,000");
        require(bytes(_name).length > 0, "Pass name missing");
        require(
            platformReserveAmount < maxTokens,
            "Platform reserve too high."
        );
        require(price > 0, "Pass price missing");
        require(bytes(cid).length > 0, "Pass CID missing");

        uint256 passId = nextPassId += 1;
        passes[passId] = Pass({
            name: _name,
            maxTokens: maxTokens,
            circulatingPublic: 0,
            circulatingReserved: 0,
            platformReserveAmount: platformReserveAmount,
            price: price,
            royalty: defaultRoyalty,
            active: false,
            cid: cid
        });

        emit PassCreatedEvent(msg.sender, passId);
    }

    function mintTo(address to, uint256 passId) external onlyRole(MINTER_ROLE) {
        Pass memory pass = passes[passId];
        uint256 circulatingPublic = passes[passId].circulatingPublic += 1;
        require(
            circulatingPublic <= pass.maxTokens - pass.platformReserveAmount,
            "All public tokens have been minted"
        );
        uint256 _tokenId = (passId * DIVIDER) + (circulatingPublic);
        tokenIdToPass[_tokenId] = passId;
       
        _mint(to, _tokenId);

        emit PassMintedEvent(to, passId, _tokenId);
    }

    function mintBatch(address[] memory to, uint256 passId) external onlyRole(MODERATOR_ROLE) {
        Pass memory pass = passes[passId];
        uint256 circulatingPublic = passes[passId].circulatingPublic;
        require(
            circulatingPublic + to.length <= pass.maxTokens - pass.platformReserveAmount,
            "not enough tokens left"
        );
        for (uint j = 0; j < to.length; j++) {
            uint256 _tokenId = (passId * DIVIDER) + (circulatingPublic += 1);
            tokenIdToPass[_tokenId] = passId;       
            _mint(to[j], _tokenId);
            emit PassMintedEvent(to[j], passId, _tokenId);
        }
        passes[passId].circulatingPublic = circulatingPublic;
    }


    function buy(uint256 passId) external payable {
        Pass memory pass = passes[passId];
        uint256 circulatingPublic = passes[passId].circulatingPublic += 1;
        require(pass.active == true, "Public sale is not open");
        require(msg.value == pass.price,"Wrong payment amount");
        require(
            circulatingPublic <= pass.maxTokens - pass.platformReserveAmount,
            "All public tokens have been minted"
        );
        uint256 _tokenId = (passId * DIVIDER) + (circulatingPublic);
        tokenIdToPass[_tokenId] = passId;
        console.log("minting ",_tokenId);

        _mint(msg.sender, _tokenId);

        emit PassMintedEvent(msg.sender, passId, _tokenId);
        sendETH(_obscuraAddress,msg.value);
    }

    function sendETH(address dest, uint amount) internal {
        (bool sent, ) = payable(dest).call{value: amount}(""); // don't use send or xfer (gas)
        require(sent, "Failed to send Ether");
    }

    function mintPlatfromReserve(uint256 passId)
        external
        onlyRole(MODERATOR_ROLE)
    {
        Pass memory pass = passes[passId];
        require(
            pass.circulatingReserved < pass.platformReserveAmount,
            "Platform reserve already minted"
        );

        uint256 firstTokenMinted = (passId * DIVIDER) +
            (pass.maxTokens - pass.platformReserveAmount) +
            1;

        passes[passId].circulatingReserved += pass.platformReserveAmount;

        for (uint256 i = 1; i <= pass.platformReserveAmount; i++) {
            uint256 _tokenId = (passId * DIVIDER) +
                (pass.maxTokens - pass.platformReserveAmount) +
                i;
            tokenIdToPass[_tokenId] = passId;
            _mint(_obscuraAddress, _tokenId);
        }

        emit PlatformReserveMintedEvent(
            _obscuraAddress,
            passId,
            firstTokenMinted
        );
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 passId = tokenIdToPass[tokenId];
        string memory passCID = passes[passId].cid;

        if ((!redeemed[tokenId]) && (bytes(passCID).length > 0)) {
            return
                string(
                    abi.encodePacked(
                        "https://arweave.net/",
                        passCID,
                        "/live-",
                        (tokenId % DIVIDER).toString(),
                        ".json"
                    )
                );
        }

        if ((redeemed[tokenId]) && (bytes(passCID).length > 0)) {
            return
                string(
                    abi.encodePacked(
                        "https://arweave.net/",
                        passCID,
                        "/redeemed-",
                        (tokenId % DIVIDER).toString(),
                        ".json"
                    )
                );
        }

        
        if (redeemed[tokenId]) return string(abi.encodePacked("https://arweave.net/", _defaultCID,"/redeemed.json"));
        return string(
            abi.encodePacked("https://arweave.net/", _defaultCID,"/live.json"));
    }

    function redeemToken(uint256 tokenId) external {
        uint256 passId = tokenIdToPass[tokenId];
        require(!redeemed[tokenId],"Pass is already redeemed");
        require(msg.sender == minterContracts[passId],"Unauthorised attempt to modify token state");
        redeemed[tokenId] = true;
        emit TokenRedeemed(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override { 
        require(!redeemed[tokenId],"Redeemed passes cannot be transferred");
        super._beforeTokenTransfer(from,to,tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
