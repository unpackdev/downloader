// SPDX-License-Identifier: MIT
// Built for Macroverse by Pagzi / NFTApi
pragma solidity ^0.8.16;

import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

/// @custom:security-contact security@pagzi.com
contract MacroverseEpics is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    error Ended();
    error NotStarted();
    error NotEOA();
    error MintTooManyAtOnce();
    error InvalidData();
    error InvalidSeries();
    error ZeroQuantity();
    error ExceedMaxSupply();
    error ExceedAllowedQuantity();
    error NotEnoughETH();
    error TicketUsed();
    error ApprovalNotEnabled();

    /* within a single storage slot */
    address public payoutWallet; //1-20
    uint256 public publicPrice; //21-24
    address public pagzi; //1-20
    uint256 public batch; //21-24
    //availability mapping
    mapping(uint256 => uint256) public available;
    //mint passes/claims
    mapping(address => uint256) public mintPasses;

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://epics.mvhq.zone/meta/";
    }

    function initialize() public initializer {
        __ERC2981_init();
        __ERC721Enumerable_init();
        __Ownable_init();
        __ERC721_init("Macroverse Epics", "Epics");
        available[0] = 1000;
        available[1] = 1000;
        available[2] = 1000;
        available[3] = 1000;
        available[4] = 1000;
        batch = 0;
        publicPrice = 0.05 ether;
        payoutWallet = address(0xd26e20bF4Aea9EC0D263c653d924D52049403823); // Payout wallet
        pagzi = address(0xFCCa03AD2B8FD14fDd4F690535EAEECaeDEB716b); // Pagzi wallet
        initMintPasses();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function approve(address to, uint256 tokenId) public override(IERC721Upgradeable,ERC721Upgradeable) {
        super.approve(to, tokenId);
    }


    /// @param quantity Amount of mints.
    /// @param series Series of the NFT to be minted.
    function claim(
        uint256[] calldata series,
        uint256[] calldata quantity
    ) external payable onlyEOA{
    uint256 reserve = mintPasses[msg.sender];
    if(reserve < 1){
        revert ExceedAllowedQuantity();
    }
    uint256 count = quantity.length;
    if(count != series.length){
        revert InvalidData();
    }
    uint256 totalQuantity;
    uint256 serie;
    for(uint256 i = 0; i < count; i++){
    serie = series[i];
    // quantity check
    if (quantity[i] == 0) {
        revert ZeroQuantity();
    }
    if(serie > batch + 5){
        revert InvalidSeries();
    }
    if(quantity[i] > available[serie]){
        revert ExceedMaxSupply();
    }
    totalQuantity += quantity[i];
    }
    //mint epics
    for(uint256 i; i < count; ++i){
    mintEpics(msg.sender, series[i], quantity[i]);
    }
    mintPasses[msg.sender] = reserve - totalQuantity;
    delete count;
    delete totalQuantity;
    delete reserve;
    delete serie;
    }

    /// @param series Series of the NFT to be minted.
    /// @param quantity Amount of mints.
    /// @param recipient Address to receive the airdrops.
    function gift(uint[] calldata series, uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Provide quantities and recipients" );
    require(series.length == recipient.length, "Provide series and quantities" );
    uint256 serie;
    for(uint i; i < recipient.length; ++i){
    serie = series[i];
    if(quantity[i] > available[serie]){
        revert ExceedMaxSupply();
    }
    if(serie > batch + 5){
        revert InvalidSeries();
    }
    //mint epics
    mintEpics(recipient[i], serie, quantity[i]);
    }
    delete serie;
    }

    /// @param to Address of the receiver.
    /// @param series Series of the NFT to be minted.
    /// @param quantity Amount of NFT to be minted.
    function mintEpics(address to, uint256 series, uint256 quantity) internal {
        unchecked{
        uint256 tokenId = (1000 * (series + 1)) - available[series];
        for (uint256 i; i < quantity; i++) {
        _safeMint(to, tokenId + i);
        }
        available[series] -= quantity;
        }
    }

    /// @param series Series of the NFT to be minted.
    /// @param quantity Amount of NFT to be minted.
    function mint(
        uint256[] calldata series,
        uint256[] calldata quantity
    ) external payable onlyEOA {
        uint256 count = quantity.length;
        if(count != series.length){
            revert InvalidData();
        }
        uint256 totalQuantity;    
        uint256 serie;
        for(uint256 i = 0; i < count; i++){
        serie = series[i];
        // quantity check
        if (quantity[i] == 0) {
            revert ZeroQuantity();
        }
        if(quantity[i] > available[serie]){
            revert ExceedMaxSupply();
        }
        if(serie > batch + 5){
            revert InvalidSeries();
        }
        totalQuantity += quantity[i];
        }
        // price check
        if (msg.value < totalQuantity * publicPrice) {
            revert NotEnoughETH();
        }
        //mint epics
        for(uint256 i; i < count; ++i){
        mintEpics(msg.sender, series[i], quantity[i]);
        }
        delete count;
        delete totalQuantity;
        delete serie;
    }

    function setPayoutWallet(address _payoutWallet) external onlyOwner {
        payoutWallet = _payoutWallet;
    }

    function setMintPrice(uint256 newPrice_) external onlyOwner {
        publicPrice = newPrice_;
    }

    function setBatch(uint256 _batch) external onlyOwner {
        batch = _batch;
    }

    function setAvailability(uint256 series, uint256 availability) external onlyOwner {
        available[series] = availability;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setMintPass(address _address,uint256 _quantity) external onlyOwner {
        mintPasses[_address] = _quantity;
    }

    function setMintPasses(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
            mintPasses[_addresses[i]] = _amounts[i];
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(pagzi).transfer((balance * 200) / 1000);
        payable(payoutWallet).transfer((balance * 800) / 1000);
    }
    //internal
    function initMintPasses() internal {
    mintPasses[0x002CB5df3a89BF87497ba6B8999A9413f3Ff40e5] = 1;
    mintPasses[0x1E33c3F17b123B43C102b9826E874e00C458cf58] = 1;
    mintPasses[0x1f60263ee43Bda39B40DecA1c25d571a8B9FA941] = 1;
    mintPasses[0x220eE648EBE5bb4FE52CB24898d51E4449EFA42b] = 1;
    mintPasses[0x25C64A1D4d174C12c46cB06458a2db5b94a210bB] = 1;
    mintPasses[0x2B40E244696393B5C1c6c3541A0816AfD327fa96] = 1;
    mintPasses[0x35135671c2E46D4a16DBfFaf2348e06c7041e664] = 1;
    mintPasses[0x56e66A54CC82654B4C12bC607b428Dcfd4a67D21] = 1;
    mintPasses[0x59DBCE846aA40F138D805a7CeBe2AFb0c33066A3] = 1;
    mintPasses[0x5E05f0fd512E52e595BAaA607d3deBC10b213952] = 1;
    mintPasses[0x5e39E3f6f04E60851A23673c8A0C79E46F48Af1f] = 1;
    mintPasses[0x5e4f4e4618C76109307EA7542012Bd8BeBDb8E81] = 1;
    mintPasses[0x67A50fF70d234D89B59Ed3DCBfAd65c4b96e1fa1] = 1;
    mintPasses[0x6Ec4999801bF4bdaB5f5676522136f69286Ceb8b] = 1;
    mintPasses[0x71fF970AF6F2f03F757413DA3e40C959D645faaC] = 1;
    mintPasses[0x766eEf67902f0DD67B63004b85a615423B034989] = 1;
    mintPasses[0x78dd22d02a024226D733Bc1dDa35BDB3cbcd2Ba2] = 1;
    mintPasses[0x7e18D5Ab6c2e07D130d8C9810f90a9e1B64DD525] = 1;
    mintPasses[0xA0592643B2f033247B56abA944D362dD0d0E6F66] = 1;
    mintPasses[0xA160260d675b8AC1698bDbC277Dad303597E78BD] = 1;
    mintPasses[0xA2d8c873F5bD8E53922b7F18390FB18A670FC58B] = 1;
    mintPasses[0xa8bd82A0Bd23206F707407276d08fAF44879BA57] = 1;
    mintPasses[0xb184Ee9D38b383F73F8ce98065C8A4556B5c2E42] = 1;
    mintPasses[0xb1C72FEe77254725D365Be0f9cc1667F94Ee7967] = 1;
    mintPasses[0xc81fc12235C03f96c8c9e31eeA71FCF1098cDcbD] = 1;
    mintPasses[0xcA892305F7a1F148C2A1a02f580A51720cD57f59] = 1;
    mintPasses[0xCb7f2Fb6f83654E769e037C8d937f96Ea55658a4] = 1;
    mintPasses[0xD6d27C78BE6EE9D9ffCAB3846FB50025BB06891e] = 1;
    mintPasses[0xECF6D08658b1a13fB6EF9966cbbf7D3fd582bA10] = 1;
    mintPasses[0xEd49C8E4Cab72B3607e195b960b4De8Bf95Dae66] = 1;
    mintPasses[0x5733642623d880A7812c4fd27b8dC1a4aDf9a2A5] = 1;
    mintPasses[0x6b7265F40B77eD1Bd6116c250c8eb386D87b2bE8] = 1;
    mintPasses[0xB3c64a8318131802c2D77cCEb9AF7e5412196397] = 1;
    mintPasses[0x230FcED7feAeD9DfFC256B93B8F0c9195a743c89] = 1;
    mintPasses[0x310121a23BDD6494360A9fF1ed27D639dFCD2691] = 1;
    mintPasses[0x22603939A7B086064A66B9dEE79eB7e73Ae1e110] = 1;
    mintPasses[0x7d8673f294f1ddc2e703a01AF3205Fb98a984a58] = 1;
    mintPasses[0x75A473c33bFfB61E945D86B37113c0859965A789] = 1;
    mintPasses[0xD769bE44b62f4eE8b1D93DfBA8ebC252b51B0EA3] = 1;
    mintPasses[0x6F4E4664E9B519DEAB043676D9Aafe6c9621C088] = 1;
    mintPasses[0xd0214b7e8a7821A5Cb07024Bc00D64ece8Cc1067] = 1;
    mintPasses[0xd6E76407A5353Cc9eD09636c45A2be8C7aC7e25E] = 1;
    mintPasses[0xFEF11555ce7e2c217a6D798c1b9Eb3b18aB884a3] = 1;
    mintPasses[0x8f42DE2b1c14267495912c0ae581da0375d8bb5E] = 1;
    mintPasses[0x36067C41Eb00b91e0607433E7F4FCAfc3F3FBEc0] = 1;
    mintPasses[0x5E05f0fd512E52e595BAaA607d3deBC10b213952] = 1;
    mintPasses[0xbFFD68de16C8B80b5A3a7A3DfD493b877cbF2EDb] = 1;
    mintPasses[0xdB782bc0C0d17D09ee74897f3e80B6cd1FB16596] = 1;
    mintPasses[0xa3668d4848e53e571D7A69561a1d8ca59732Dcfe] = 1;
    mintPasses[0x1FffaC0101e4604A83bbB5bB0d783c965C2c6f21] = 1;
    mintPasses[0xe568ca143592DF06A7EABfd4d9D563F1289dc607] = 1;
    mintPasses[0x17526dD2955c6d7b4450BF066d196d7001E70804] = 1;
    mintPasses[0x4904A2f99ABAfC72cD6f270f2A37d3F5C5E92c41] = 1;
    mintPasses[0x302430F7c2A3e83DD193de542ac106f429281bF0] = 2;
    mintPasses[0x339eF4a59709e4710658cD232e96Ed8a00e158bC] = 2;
    mintPasses[0x59DBCE846aA40F138D805a7CeBe2AFb0c33066A3] = 2;
    mintPasses[0x640EA6c41cD910DB4FB1652B4422255FA3fd4707] = 2;
    mintPasses[0x8500C52ca27f326D3a64B792aA215B1166503076] = 2;
    mintPasses[0x89A5370C5EE3b20ebD0a95C13Fa24150A4Ac9c8C] = 2;
    mintPasses[0xB2E0f2fb1313FCD8870D683A812a35a483e4E843] = 2;
    mintPasses[0xB8c563229DF762bB62eaeeA7D1E2DFF7B620592b] = 2;
    mintPasses[0xA39C8CC08700E6211e58eE894c373f8E798A38b9] = 2;
    mintPasses[0x12cA8A5011EA885F093cFFb26749D889Eb052Bd9] = 2;
    mintPasses[0x270AC27532824e2e4A57Abc75719a3f8017e1B01] = 2;
    mintPasses[0x591F8a2deCC1c86cce0c7Bea22Fa921c2c72fb95] = 2;
    mintPasses[0xF1ff23e094C3f83C39d1F5deb92A3e72Ca501cFc] = 2;
    mintPasses[0x8500C52ca27f326D3a64B792aA215B1166503076] = 2;
    mintPasses[0x18e591821968e2692Fa6e0Bc27394d704FA6aeC9] = 2;
    mintPasses[0x96872A657f9bd9ABF73a3ceB90f5dD2550473660] = 3;
    mintPasses[0xCA6E2533348766b743e329C19c21aDd3b645bEf0] = 3;
    mintPasses[0x886478D3cf9581B624CB35b5446693Fc8A58B787] = 3;
    mintPasses[0x41FD3dC049F8c1aC6670dE119698D3488017c0b6] = 5;
    mintPasses[0xCE603Ee9199708f6aFBcF1F98Be1f976Cd5ddeD0] = 5;
    mintPasses[0xeF05f2f9758Ceb1CC3Ed6369a3Bf861B7094Ba48] = 5;
    mintPasses[0x04aFa47203132436Cd4aAFA10547304B25F7006B] = 6;
    mintPasses[0x275715709500a38a86fA48D280Ed88D201681601] = 6;
    mintPasses[0x531e25A46b61828dd44552468199a7B81Ae3e6E7] = 10;
    mintPasses[0x6fa1D14fB34C002c30419BbBFfD725e0A70B43Aa] = 10;
    mintPasses[0xE2542857B06Ae5cdf7c4664f417e7a56312Da84E] = 10;
    mintPasses[0x738e3f60c8F476C067d49f25B21580f88eBea81A] = 10;
    mintPasses[0x94DE89287e3C05d508A3Fcd322A798c9f96c926e] = 10;
    mintPasses[0x83E8c948C532aE133BB55Fce2C9E8873cbc2Dca8] = 10;
    mintPasses[0xF4617b57ad853f4Bc2Ce3f06C0D74958c240633c] = 25;
    mintPasses[0x89F4b60f801D59442ACC34ea417131c53c6BC986] = 500;
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable,ERC2981Upgradeable,ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
