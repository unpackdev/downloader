// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";

interface ISkullNBananasGadgets {
    function ownerMintForAddress(
        address _recipientAccount,
        uint256 _id,
        uint256 _amount
    ) external;
}

interface ISkullNBananasCollection {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract SkullNBananasGadgetsFreeMint is Ownable {
    mapping(address => uint16) public addressMapping;
    mapping(address => bool) public hasClaimedFreeGadget;

    uint256 public freeGadgetId;

    ISkullNBananasGadgets public gadgetsContractAddress;
    ISkullNBananasCollection public collectionContractAddress;

    address[] private addresses = [
        0x17e02a5DB177725505820e3a5C33f3570c5C3310,
        0xB0f318E42d967808c1669571d61fd6e21ADB1176,
        0x2D7a74B2D7e2e37Ddd81b44b821cBeB581cf26c9,
        0xBdaFf5d154D80cAC102Ec38239719b172bB781A0,
        0x22b6a6f39c07c689fa5C1C71E0769483e8186dC8,
        0xF568a3b53E283d25cbca49Ec600F7F80af5fE625,
        0xe9DbfDc7d19a365623cC57395B3953345F33606A,
        0xA68386D3592d425F08876C1D850100a42e44554B,
        0xDf6c0834cEb76c025e0Fb1BB6C41F9110C37b4f1,
        0x697fFe382b9C01Eb6C5A76550a50860F10DB144A,
        0x720EA94bf57228a9F7C17639c3981A5F300d1098,
        0xfd87EEc11F467971f953a085933a07d8FBC247A3,
        0x03827309eF4f31d0BBAc02eCB9c6EC0DBd819Fa4,
        0x29e546a6969Db7a5637f05011fbc8eB84c41cBa1,
        0xac635694Ef9E1da5dC263a30FCED0B675d6bB3d5,
        0xCA7F0662A8cfe766Bba982B31cc5DdA5A0f1a655,
        0xf20C9b18e1b8bBC063da9Ef18005D5760CBF1876,
        0xc7125eF179F6e6b29EA461F20AD415E54D250211,
        0xeaFc446672E9a011e32e2501051a6f3111dA4b49,
        0xFAdb2A005Cf95F49fBF9B2180DaF3545cF32D7f6,
        0x2c35dFBAfC30F55662e91b6296f9Cf47238c81d3,
        0x44a584B709eCD27369a7484d48bF64eae2FafE85,
        0x3455F665e8df4ed84892f56bDb0BBE974aD96128,
        0xE36bCAd5Cc643D9e5f410F261e51623e900D58a8,
        0x19DA9096939eAf1a5c5e80196dbdbA8e1dc9fB3D,
        0x561b33f35D354BcA5E0BEB2bf56ea0C6bE5eBe45,
        0x3768D5460a9341833C63Af1f51c0061158008c4E,
        0x9EaD143bd86A94E8eBb2651CC128DE089EC6d513,
        0xdAb1a1854214684acE522439684a145E62505233,
        0x9E0daFe2BDa9B9645d5a17EbE02B22306A1c0228,
        0xbaA552EC41FF2417fb8D0531AAF2E92b4780aee5,
        0x4dBd057aEa218F498A9B660f6cfdf6CE86Bf8De7,
        0x9450F6dDfb0D9BEde4afF3434274711E97fAb325,
        0x56564af6d67D112f26E50Ca3F6986e2420Fd7BDE,
        0x280D9f1e40DB2B727Cb08018276a6f03541a22f2,
        0x69395Bf888e9E651b9Df34F3CC20cBa8a78fF3D6,
        0xBAa6Ce50594Ab1B4929118FDe5Bf566BC10426e5,
        0x622581b700469599e9F03d4d4c1fD506010b94fe,
        0xA48d7df1Cc2BD4C08DEF0F95eb53Cb1508Be12Cb,
        0x3EB5F7acd0dCa6363F06dA06F22E1ad95662685B,
        0x2F2d413F0de14B1CCB8B9EdCFe87D95e061EE673,
        0xa01ff8E3d13b42e05F506876d58DBFc119f75EB1,
        0x872CaB911c71242eC5461cb7F0AeB9560996baB3,
        0x98916025D2e79c71D0221432976A7FDB8B6402d6,
        0x974687B24cd5A21A536F7E12E843846fe71808D1,
        0x267428F735c0839a2F318c04d177da987cA8Ed6C,
        0xd34129144bcFEA91e240d11c80fdBAa848B9458B,
        0xefB2607cA778A43D7c0ae46A91AAdD7795279bb4,
        0x3A94BdfC04dbdC35110b87D27C7F6B5568be4676,
        0xa8C10eC49dF815e73A881ABbE0Aa7b210f39E2Df,
        0xD7e2D7749Ee320aAB2b5DC400CE8ab1E3c20fF3d,
        0x10E10F098F7A57756565a9ae4e20CE4da801b803,
        0xf826Fc01bf3e5C472105A7811E27973B555A1139,
        0x0aA03f65C0f2C4e036759afDbafCA3dA825fa708,
        0x68b02672410AeCC65eb1FFD3fF4Aa3578461EA3d,
        0xC4b6fC9678b7097808041BEBf236252300784686,
        0x89796A5cDbB99c2FBEF2C3E313CcB30c0410B947,
        0xF8159FF65ef39E242dE7591c90E21c19Ac5276fB,
        0x1E06601411b553E3C69e49E754286246Fd469a73,
        0x7730bDE0cE4d9970a0dE3E83248BbDa1d5a3E7E8,
        0xF130823618b6764a9b054A452880d90D027CEe7E,
        0x8905EB929C323763Db494cdfCd12D84bdd0a7835,
        0x0452a84Fc3197A3E8E6900EF561c621D397D3be5,
        0x6E1FE8C0D1D1259B09111D75bE7539eC10615Ab8,
        0x1cA89DD09eB8FA5eAC5a38b645d64434a47162A8,
        0x18b31Cdbc5C3A5782d8828dB9e4596aC809736D6
    ];

    uint16[] private amounts = [
        1,
        1,
        2,
        1,
        2,
        1,
        2,
        4,
        1,
        2,
        1,
        14,
        6,
        2,
        1,
        2,
        31,
        43,
        1,
        1,
        3,
        1,
        3,
        41,
        2,
        1,
        3,
        7,
        81,
        1,
        1,
        2,
        2,
        1,
        1,
        1,
        2,
        1,
        1,
        1,
        1,
        1,
        1,
        2,
        1,
        1,
        3,
        1,
        1,
        71,
        1,
        1,
        1,
        1,
        1,
        2,
        6,
        2,
        1,
        5,
        10,
        10,
        1,
        14,
        2,
        1
    ];

    constructor() {
        gadgetsContractAddress = ISkullNBananasGadgets(
            0x3C0412D5eAB01F169C8Cc5bEDDB97c482c5B53d9
        );
        collectionContractAddress = ISkullNBananasCollection(
            0x9a9813752Cf595e5013CA39c1aaa3f5458a30dC5
        );
        freeGadgetId = 1048;
        addAddress(addresses, amounts);
    }

    function setGadgetsContractAddress(
        ISkullNBananasGadgets _contractAddress
    ) public onlyOwner {
        gadgetsContractAddress = _contractAddress;
    }

    function setCollectionContractAddress(
        ISkullNBananasCollection _contractAddress
    ) public onlyOwner {
        collectionContractAddress = _contractAddress;
    }

    function setFreeMintId(uint256 _id) public onlyOwner {
        freeGadgetId = _id;
    }

    function addAddress(
        address[] memory _addresses,
        uint16[] memory _nftToSend
    ) public onlyOwner {
        require(
            _addresses.length == _nftToSend.length,
            "Addresses and NFTs to send must be the same length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            addressMapping[_addresses[i]] = _nftToSend[i];
        }
    }

    function gadgetsFreeMint(uint256[] memory _id) public {
        uint16 nftToSend = addressMapping[msg.sender];
        require(nftToSend > 0, "No NFT to redeem");
        require(_id.length <= nftToSend, "You can't redeem this many items");

        for (uint i = 0; i < _id.length; i++) {
            gadgetsContractAddress.ownerMintForAddress(msg.sender, _id[i], 1);
        }

        addressMapping[msg.sender] -= uint16(_id.length);
    }

    function cupFreeMint() public {
        require(
            !hasClaimedFreeGadget[msg.sender],
            "Free gadget already claimed"
        );
        require(
            collectionContractAddress.balanceOf(msg.sender) > 0,
            "Can't redeem any free gadget"
        );

        gadgetsContractAddress.ownerMintForAddress(msg.sender, freeGadgetId, 1);

        hasClaimedFreeGadget[msg.sender] = true;
    }
}
