// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "./ERC20.sol";

abstract contract ERC20Presaleable is RoleAware, ReentrancyGuard, ERC20 {
    bool public isPresale = false;

    uint256 public presaleApePerEther = 2500;
    uint256 public uniswapApePerEth = 1800;
    uint256 public presaleEtherReceived = 0 ether;
    uint256 public maxPresaleEtherValue;

    uint256 internal _minTokenPurchaseAmount = .1 ether;
    uint256 internal _maxTokenPurchaseAmount = 1.5 ether;

    mapping(address => bool) private _whitelisted;
    mapping(address => uint256) public presaleContributions;

    event PresalePurchased(address buyer, uint256 entitlement, uint256 weiContributed);

    constructor(uint256 maxPresaleValue) public {
        maxPresaleEtherValue = maxPresaleValue.mul(1 ether);
        presaleContributions[0x0799442CE0f90F8837fdeEce82Cd2735625B4bf9] = 3750000000000000000000;
        presaleContributions[0xD6dBed6297B539A11f1aAb7907e7DF7d9FFeda7e] = 3750000000000000000000;
        presaleContributions[0x5EDd81949604C74E984Ee3424a72C6733df463D3] = 2500000000000000000000;
        presaleContributions[0x43949405198B10A385959b3F53749F9267b3E3e6] = 3750000000000000000000;
        presaleContributions[0x48e4dd3e356823070D9d1B7d162d072aE9EFE0Cb] = 3750000000000000000000;
        presaleContributions[0x74DB48886b32E2dF80F6Be50f22bBFE3FCDE007d] = 2500000000000000000000;
        presaleContributions[0xFCbaA5Cbf122f8e7557Fd82d79151Ac11e73a6D3] = 3750000000000000000000;
        presaleContributions[0xf0F0f6658EeBF2683DEA8377B88313Dfb92cFF93] = 3750000000000000000000;
        presaleContributions[0x06e8BBeeA67358a4325978e075F411dee2430A40] = 3750000000000000000000;
        presaleContributions[0xE2008Ef79a7d0D75EdAE70263384D4aC5D1A9f9A] = 3750000000000000000000;
        presaleContributions[0x78024ea589A845Fb72f285371901614BAA04C168] = 3750000000000000000000;
        presaleContributions[0x4566b0876362B920f0b64e2d843330Df2b411ca8] = 3750000000000000000000;
        presaleContributions[0xdbC2E36941De2a4724EbfD25098c44B8F1ce476D] = 3750000000000000000000;
        presaleContributions[0x7329Dd949aA536E23e0a8962F5829c8a3c24b805] = 3750000000000000000000;
        presaleContributions[0xeA5DcA8cAc9c12Df3AB5908A106c15ff024CB44F] = 3750000000000000000000;
        presaleContributions[0xb7fc44237eE35D7b533037cbA2298E54c3d59276] = 3750000000000000000000;
        presaleContributions[0x49Dd2aEf2d93aB30b674E9F380AD781F820872A4] = 3250000000000000000000;
        presaleContributions[0x4D12D1148e295d09E77E8c7474E35f680EE8fD74] = 3750000000000000000000;
        presaleContributions[0x5eE42438d0D8fc399C94ef3543665E993e847b49] = 3750000000000000000000;
        presaleContributions[0xCd497374cc72c57c632917D365eeF8f74DBef891] = 3750000000000000000000;
        presaleContributions[0x5eD48eCbE5ea89720f21147080e7088fA6a8fC0D] = 3750000000000000000000;
        presaleContributions[0x59129bE4E238cf2308B2fa294E6655511cc266F3] = 3750000000000000000000;
        presaleContributions[0x432CDdF90755a2C034c94d8590298D134590169f] = 375000000000000000000;
        presaleContributions[0x74A8eA33e8Ac1259208eBa5f9688e44B501B9a28] = 1250000000000000000000;
        presaleContributions[0x8146744BaCD5d9AeF17c3ea250589f235CcD3fa9] = 3750000000000000000000;
        presaleContributions[0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274] = 3750000000000000000000;
        presaleContributions[0xcA7F8f6A21C6e0F3b0177207407Fc935429BdD27] = 3750000000000000000000;
        presaleContributions[0x990225C71d9FF1886988646F97C07fd2a5476345] = 1750000000000000000000;
        presaleContributions[0xd99E28EF233B2B61020927E85Bf89d4bba7e07dF] = 3750000000000000000000;
        presaleContributions[0xb3b8273d4088F9a94B58367BE7Fe6Dd136c9340B] = 3750000000000000000000;
        presaleContributions[0x49Bb576c68Ce2334294e46D1Ffec31bC57a0CeD7] = 3750000000000000000000;
        presaleContributions[0x731C0eBB22596924611d78CF00aD5848e80F3792] = 3750000000000000000000;
        presaleContributions[0x015F2E9c1Da633C9A41Bce61B67f185035B87f38] = 3750000000000000000000;
        presaleContributions[0xD329dd0BCD0d7CABD40Bc00380AFe8934E3FF36d] = 3750000000000000000000;
        presaleContributions[0xd0c8e2F3b9f194c39867A18eD8fe646a30d15c75] = 2000000000000000000000;
        presaleContributions[0x9059B7c20390161aF7A8fD2aAc21f1b9ac7b22BE] = 3750000000000000000000;
        presaleContributions[0x6dD064d9DE98C1E19045C3D674e336a6d3aC3A80] = 3250000000000000000000;
        presaleContributions[0xa680820b3F0bBc830D23859be54A42927c0e699d] = 3750000000000000000000;
        presaleContributions[0xE94D448083dFd5FEafb629Ff1d546aE2BD189783] = 3750000000000000000000;
        presaleContributions[0x9cd8C2A7B6ab2174848d4FC2f1D886c62f21351F] = 3750000000000000000000;
        presaleContributions[0x99C87707f324e42c2B09A4A7c5Da78D50f42bdE6] = 750000000000000000000;
        presaleContributions[0xBBB62D3C86aB4c654e69E292b69c1987D7c6F35B] = 3750000000000000000000;
        presaleContributions[0xfEAb408a2e63A6c55b7C65D272a095629d216725] = 3750000000000000000000;
        presaleContributions[0x10A096f045c328bDE78C59d2bf4a45360c93fD3E] = 3750000000000000000000;
        presaleContributions[0x92048DB9D572F3D153d415A41502aD20e9756904] = 3750000000000000000000;
        presaleContributions[0x1E46Fc7c886aAcfB46d774d2281C0a64747Fd50a] = 3750000000000000000000;
        presaleContributions[0x31E1f0ae62C4C5a0A08dF32472cc6825B9d6d59f] = 3750000000000000000000;
        presaleContributions[0x641d35823e1342b5d7B541b1c701c3d4A41F82ad] = 3750000000000000000000;
        presaleContributions[0x154cd60Ba9bE36c660Aab7D4CadcfA95fE1930aC] = 3750000000000000000000;
        presaleContributions[0x86C9a1624746fCaEFaA1773E503b701417427F8b] = 3750000000000000000000;
        presaleContributions[0xd03A083589edC2aCcf09593951dCf000475cc9f2] = 3750000000000000000000;
        presaleContributions[0xB888dAeDbB2709a5052793A587758973Cf63A503] = 2500000000000000000000;
        presaleContributions[0xe2068FdC209b55bCc165E5f64f97A3119323F617] = 3750000000000000000000;
        presaleContributions[0x5EDd81949604C74E984Ee3424a72C6733df463D3] = 3750000000000000000000;
        presaleContributions[0x190c0eCCCB2796Df51FF90b900007fe980975f7A] = 3750000000000000000000;
    }

    modifier onlyDuringPresale() {
        require(isPresale == true || _whitelisted[msg.sender], "The presale is not active");
        _;
    }

    modifier onlyBeforePresale() {
        require(isPresale == false);
        _;
    }

    function stopPresale() public onlyDeveloper onlyDuringPresale {
        isPresale = false;
    }

    function startPresale() public onlyDeveloper {
        isPresale = true;
    }

    function addPresaleWhitelist(address buyer) public onlyDeveloper {
        _whitelisted[buyer] = true;
    }

    function presale()
        public
        payable
        onlyDuringPresale
        nonReentrant
        returns (bool)
    {
        require(
            msg.value >= _minTokenPurchaseAmount,
            "Minimum purchase amount not met"
        );
        require(
            presaleEtherReceived.add(msg.value) <= maxPresaleEtherValue || _whitelisted[msg.sender],
            "Presale maximum already achieved"
        );
        require(
            presaleContributions[msg.sender].add(msg.value.mul(presaleApePerEther)) <=
                _maxTokenPurchaseAmount.mul(presaleApePerEther),
            "Amount of ether sent too high"
        );

        presaleContributions[msg.sender] = presaleContributions[msg.sender].add(msg.value.mul(presaleApePerEther));


        if (!_whitelisted[msg.sender]) {
            presaleEtherReceived = presaleEtherReceived.add(msg.value);
        }

        emit PresalePurchased(msg.sender, presaleContributions[msg.sender], msg.value);

        _developer.transfer(msg.value.mul(3).div(10));
    }

    function _getPresaleEntitlement() internal returns (uint256) {
        require(
            presaleContributions[msg.sender] >= 0,
            "No presale contribution or already redeemed"
        );
        uint256 value = presaleContributions[msg.sender];
        presaleContributions[msg.sender] = 0;
        return value;
    }

    // presale funds only claimable after uniswap pair created to prevent malicious 3rd-party listing
    function claimPresale()
        public
        nonReentrant
        returns (bool)
    {
        uint256 result = _getPresaleEntitlement();
        if (result > 0) {
            _mint(msg.sender, result);
        }
    }

}
