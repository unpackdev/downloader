// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";

contract CreatorsoftheEnd is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(
    address baseFactory,
    string memory customBaseURI_,
    address accessTokenAddress_
  )
    ERC721Delegated(
      baseFactory,
      "Creators of the End",
      "CofTE",
      ConfigSettings({
        royaltyBps: 650,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {
    accessTokenAddress = accessTokenAddress_;

    allowedMintCountMap[msg.sender] = 50;

    allowedMintCountMap[0xFc54a7dE00e41ca367a87901562b265b0DB38a62] = 1;

    allowedMintCountMap[0xfc3F72a98F74aa7F7656B81e4C6F9c8DA725d53e] = 1;

    allowedMintCountMap[0xfbfD8701694BD021DF098061a6AF167D871FADc0] = 1;

    allowedMintCountMap[0xF3D8aCae365d46330a2602c312A232dB69A204D3] = 1;

    allowedMintCountMap[0xeD1202eC3c05dB6D1B2826e6C0FfA65654c1AB64] = 1;

    allowedMintCountMap[0xEcC55f5e5967995F40911Ee9f21d6635DDE4A388] = 1;

    allowedMintCountMap[0xEb27c5B926C17f726957a15a86DC1f5B435b68Ee] = 1;

    allowedMintCountMap[0xdf4383Bc0855768ABa61E7d38310AF03249eE4C5] = 1;

    allowedMintCountMap[0xdDd3227CC48D04E5eA17E8B9dEf870c45160501E] = 1;

    allowedMintCountMap[0xD8f2c8dE147EdE45D00c1f1ba529Db5486F8b922] = 1;

    allowedMintCountMap[0xd50a805a547Ed4f8dA3602615e77Ab9281A0560A] = 1;

    allowedMintCountMap[0xCD842afF23394f57496b4625F82D621f0576BCA2] = 1;

    allowedMintCountMap[0xC78E80F0E6233F8071848F05F2C7ab37B585D25b] = 1;

    allowedMintCountMap[0xc75F33baC14989FFC269211250f60e497D013A57] = 1;

    allowedMintCountMap[0xbd16b6cf36301Bb279798aA39Bd0E19C5faa7BB6] = 1;

    allowedMintCountMap[0xbD00DA747155CF6668DC84a2541BB90EDb72920b] = 1;

    allowedMintCountMap[0xb76765970de10674392c05528650E7cfD32C658c] = 1;

    allowedMintCountMap[0xaa8A85d3e1c8A6dB2f485ef01fBE8BD6Cc593519] = 1;

    allowedMintCountMap[0xA9821681fEF27Ed817DF77E476DDDAf0aDac4443] = 1;

    allowedMintCountMap[0xA574225Ffa9b40db38D387B041484c0C1a499098] = 1;

    allowedMintCountMap[0xEbdfbF296911535F5dfecD82D91b9551B7440040] = 1;

    allowedMintCountMap[0xa263A66057a6bfA095e35ab472B49455Aa1D73F6] = 1;

    allowedMintCountMap[0x85684C11FD750506CD8783a7cDC19Bc583ce62f8] = 1;

    allowedMintCountMap[0x81e1A1fE8841f037Fb8C395f8f001f01BB3A70e3] = 1;

    allowedMintCountMap[0x819Aa1675c4baBa624A5E061F4F4cE05095A4AC2] = 1;

    allowedMintCountMap[0x81239DcB535b9868b2e622a1EEAd983F4E5E9bE8] = 1;

    allowedMintCountMap[0x6Fc5891d3daF91555f7b9C70eB9657A4dF59176f] = 1;

    allowedMintCountMap[0x67C1910D108abc66Dc103Ff20b4E2054981E1971] = 1;

    allowedMintCountMap[0x60612025FDaef4ED17Db1F7B2d09A6949271Fee2] = 1;

    allowedMintCountMap[0x5Dc2Dabd4c5093a9f3CADD4568f9A0bb109bcf28] = 1;

    allowedMintCountMap[0x5aB35A4E396c89D86efA12ba6796425b0a19c9A6] = 1;

    allowedMintCountMap[0x57a678F36B3978d3Af834636397AF03181dC4696] = 1;

    allowedMintCountMap[0x5530D8aCBA16918eCcA9578A46897bFC5eBA8D93] = 1;

    allowedMintCountMap[0x514AefEc59d83605Eb25B1BDE5eeC36F45aB4238] = 1;

    allowedMintCountMap[0x4C51D1D18d8F6f76a55b0a18f7a3b23De36357e4] = 1;

    allowedMintCountMap[0x48D0F208DAcf70A94b5A009feaE0cf33B63B4039] = 1;

    allowedMintCountMap[0x48aD8Cc90760c64114cf9Ae349C8B4b99480Eada] = 1;

    allowedMintCountMap[0x47ff8522c668b8D000104B94cE9d322A4cc2d591] = 1;

    allowedMintCountMap[0x40a8232E09F10920Abeb21730437cCA2b07cA83c] = 1;

    allowedMintCountMap[0x3ddC07ECDE02A1D92F70e88551d9666712A837F3] = 1;

    allowedMintCountMap[0x3C85eC90D19d56a93F3a662bfEFb2072a38dE309] = 1;

    allowedMintCountMap[0x2E674A7c96cE00d28590A2F51f0F37D8c1226458] = 1;

    allowedMintCountMap[0x24752612a5d5cB837FAeae6829d448BBF8B37b24] = 1;

    allowedMintCountMap[0x22F057B5189D796E9B56159774A701b563280B2C] = 1;

    allowedMintCountMap[0x0b0F9f02d9aEF778433dea88C4BEC341D6C86834] = 1;

    allowedMintCountMap[0xfe01e4f001bd406Fc1DCDd47323e5179Ea3EB16D] = 1;

    allowedMintCountMap[0xf2C7F66A54A14d642C7998b05177F41b70398A01] = 1;

    allowedMintCountMap[0xe6d6c64a981385f2e93196833a162655d6F8a8Fb] = 1;

    allowedMintCountMap[0xdf9e6a194F3d4DC2571158F4bA7CFA9696AA9274] = 1;

    allowedMintCountMap[0xd628028d8C49178b7e955b5A1A2e7C336dc40981] = 1;

    allowedMintCountMap[0xd60d26B3CfB19f2491d2EA5567E7Bd81C221B3a4] = 1;

    allowedMintCountMap[0xc73eA8D62Fb8EaEaDfa0DA5D2681185c8Bb8518D] = 1;

    allowedMintCountMap[0xb7905247daA1E10CF2Ebc70A47DCFF5fDD498b40] = 1;

    allowedMintCountMap[0xB719e142B085B47Ca19905F0c0c325C5f937ACFb] = 1;

    allowedMintCountMap[0xB5bAB3869d8bC4aAa9E0566775F3aB957fE7ab62] = 1;

    allowedMintCountMap[0xA7D775FB03F699bEAbbdc18FF97D1385feeB3EB9] = 1;

    allowedMintCountMap[0x8E74351b6C91e729395560438f6c85a16dD4cce4] = 1;

    allowedMintCountMap[0x85cA7d812127677FFE9B5672DA40459348a8FF85] = 1;

    allowedMintCountMap[0x7f5afC67d4C3AE0182354ea6e785FdEb20150f15] = 1;

    allowedMintCountMap[0x7e4208F22CBEd02599611cf096eB33E021670507] = 1;

    allowedMintCountMap[0x7c192a1fF95c3254abc1B34B493E2fFCCdF3836F] = 1;

    allowedMintCountMap[0x78161b0c34DA8bBf88DC73bC214d37616A927ae7] = 1;

    allowedMintCountMap[0x6e1596069691c84aA7eFD19C573F190eF84601C6] = 1;

    allowedMintCountMap[0x69DEE1c2B5115a1a89d16F132Ee3DaAee7cFf49b] = 1;

    allowedMintCountMap[0x650b4D231A9bEB088B5470A91a423E2eef2005e4] = 1;

    allowedMintCountMap[0x63C242920eD0e137cC7cBc6D2cDB5B1fccD050cE] = 1;

    allowedMintCountMap[0x5a6cc3595a4286a751704D9DCc66439b808a5B94] = 1;

    allowedMintCountMap[0x3ddf02F2d6E3afe2b0118a79B3656A5d88DAaAAd] = 1;

    allowedMintCountMap[0x2EE54D8eB4F898c285b9fce4320D0bA6725E1704] = 1;

    allowedMintCountMap[0x16b98EB1cfE89Bf86aED9Cd1AcBacf8e4985d6A0] = 1;

    allowedMintCountMap[0x10084538C56D09f84A955bde83A892aB67af247c] = 1;

    allowedMintCountMap[0x03d0f9aEFF01352dD162f7e1c76d0efd6fF3011d] = 1;

    allowedMintCountMap[0xE31B7d9ad27df4B0EdCce4794A75d434b50F72D0] = 2;

    allowedMintCountMap[0xD00904B190e1cc6436f688c400cbb5050a74f81c] = 2;

    allowedMintCountMap[0xc98f40C479eB6066BF34276084401c1CD3ad8f30] = 2;

    allowedMintCountMap[0xBcd645Da5c16203b79462E6d27E8529499bdDa6d] = 2;

    allowedMintCountMap[0xBb0E7f7E42b82361B1C14BD9dD9A581b8d43D45E] = 2;

    allowedMintCountMap[0xbA292F269fe25204fC8aEAb657bA7B32F2fac87A] = 2;

    allowedMintCountMap[0xB58D73997C1CA0E1812c60A7eC69683eEFc098B8] = 2;

    allowedMintCountMap[0x991f7e09ef8638B4097829169aD7FBf482c65864] = 2;

    allowedMintCountMap[0x8a588E88547E0c72f2A1628f4Cb01FBc0B04bfb5] = 2;

    allowedMintCountMap[0x4e07751EA822dBc8c71B1aC89e971Ed88a089b3f] = 2;

    allowedMintCountMap[0x1e4b192aFc4C39E88C747F8a7171636BB38B4c7e] = 2;

    allowedMintCountMap[0x142875238256444be2243b01CBe613B0Fac3f64E] = 2;

    allowedMintCountMap[0x13706B0C0FB41011B5B92339cCd36588bc06B635] = 2;

    allowedMintCountMap[0x0aC5c02E01D7d18661cd20491C63ca6117c7Fcd6] = 2;

    allowedMintCountMap[0xD3910DB0Bf6e432C665A8Bfdf46af43aa108c8e7] = 3;

    allowedMintCountMap[0x958397e3CC0DAbcA43C57589CDC18Db23D435DE4] = 3;

    allowedMintCountMap[0xed9bc6D5bC76A45E4302f573895d6d21D1Ab96f7] = 4;

    allowedMintCountMap[0x47b20272EBeE4233Aad387dd88Aa80DDaF55032B] = 5;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 1;

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a >= b ? a : b;
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    if (saleIsActive) {
      return (
        max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
        mintCountMap[minter]
      );
    }

    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  address public immutable accessTokenAddress;

  uint256 public constant MAX_SUPPLY = 720;

  Counters.Counter private supplyCounter;

  function mint() public nonReentrant {
    if (allowedMintCount(msg.sender) >= 1) {
      updateMintCount(msg.sender, 1);
    } else {
      revert(saleIsActive ? "Minting limit exceeded" : "Sale not active");
    }

    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");

    IERC721 accessToken = IERC721(accessTokenAddress);

    require(accessToken.balanceOf(msg.sender) > 0, "Access token not owned");

    _mint(msg.sender, totalSupply());

    supplyCounter.increment();
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_tokenURI(tokenId), ".json"));
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so