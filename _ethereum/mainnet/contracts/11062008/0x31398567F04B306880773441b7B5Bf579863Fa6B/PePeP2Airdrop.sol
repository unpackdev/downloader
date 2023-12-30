pragma solidity ^0.4.18;

contract ERC20 {
    function transfer(address _to, uint256 _value) public returns (bool);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);
}

contract PePeP2Airdrop {
    ERC20 public token;
    address public owner;
    mapping(address => bool) public Recipients;
    mapping(address => bool) public Wallets;

    function PePeP2Airdrop(address _tokenAddr) public {
        token = ERC20(_tokenAddr);
        owner = msg.sender;

        // Recipients
        Recipients[0x8828c7d46fe76224dDdc7F58D2d48887DB2E0f1b] = true; // 1
        Recipients[0xe612b7408B0481d2b37D8cC2445DE4f9Fb980857] = true; // 2
        Recipients[0xd672a386A8b68E250a7097e4C3a0f2bA8E15deB4] = true; // 3
        Recipients[0xF79ECde507DAf989f4a49865b9ab670f6C194525] = true; // 4
        Recipients[0x9E2557d27D118581A6CD2C7bEF8F3C5a256FAdc2] = true; // 5
        Recipients[0xe1BAB62D4aA76B691C32B8bC989f8b51683940d7] = true; // 6
        Recipients[0x2dc95771Cd496dA38f7B78814c7e062296417709] = true; // 7
        Recipients[0x6ea9eFe2B319A31EcD92C28b53185048413AD8Bd] = true; // 8
        Recipients[0xCE3dB46891CD513A3Eb962Ce7F51A871f1AD7c71] = true; // 9
        Recipients[0xbDe56A18d99F88b2a50FB79a8b99Cdbf53108bF0] = true; // 10
        Recipients[0xB5B1b8b5aad7685fa74c3fE842D24451E1acF44F] = true; // 11
        Recipients[0x08EBfCbDAC5cEe8261eb84aB230EDfF29c4A504f] = true; // 12
        Recipients[0x63c6Ba2F209a8Fe5365868e2d1AC97067bCf7C1D] = true; // 13
        Recipients[0xcd16ACbE184A7B87eaD571d96577d147889b2580] = true; // 14
        Recipients[0x98C82331B4792681f3fAA797aE7EC49ffD7D26Dc] = true; // 15
        Recipients[0xC71Af5642fD4700Ae349eC4e323559127092E002] = true; // 16
        Recipients[0x48F614535e33d803932dF2853089feC9FD3B6f93] = true; // 17
        Recipients[0xAA361bdcbC1f47c97fAeFDBbFaED25832a1f17B1] = true; // 18
        Recipients[0x52186AE68C278F79860095AEd518046094Fd2F41] = true; // 19
        Recipients[0xd8067e2C4bDC2B5EFf40753E02485C48ba7c57cf] = true; // 20
        Recipients[0x99C13cB5f66Ad6e221426Ac5eED94a227809eB29] = true; // 21
        Recipients[0xBaC48f30111d05D27c001bD6c060b17e0907Ac34] = true; // 22
        Recipients[0xdD2E06df915Ed42168afA8AF86673Cd11C93269a] = true; // 23
        Recipients[0xfB7b6c967a598F9d952c7E91824b729bE3771b09] = true; // 24
        Recipients[0x8fCEEfB832075a554066d522C41362E1b7620b27] = true; // 25
        Recipients[0xEcfe286A8A7fd8e476e56f8ECF29e1862C86EF48] = true; // 26
        Recipients[0xc9AE12a9d29Df20fACeb16E9ae370C35013AA835] = true; // 27
        Recipients[0x5e2571464FaF68AE12508B34f71C8Daf18557E5d] = true; // 28
        Recipients[0x556c05B20b9864cEF780Bd89a7BC032D1F1b9576] = true; // 29
        Recipients[0x9fb4407fA50fd04c653d6564C09498C054E2888c] = true; // 30
        Recipients[0xab7637090910620390b678916f56a03762e47ca3] = true; // 31
        Recipients[0xD49AB02079Cc8fF62b7A1728975b2Db7b4538FD8] = true; // 32
        Recipients[0x5a49968b2BB243f08079A38062B6419b536eCD96] = true; // 33
        Recipients[0x6A199f2c0bC8296CBA13449641089D1A7b420202] = true; // 34
        Recipients[0x154b3beA38a5d69d2CFB62d2Db7c274d1e70C2d8] = true; // 35
        Recipients[0x300Ab66503f2AB43ec5E625703Ec7B2D6C5c6e66] = true; // 36
        Recipients[0x9fd41a4A21750AaD13c183B82B598928e8A445dc] = true; // 37
        Recipients[0xD2d93B1D03732b13A91a9e4eAaEd69Bd6A7ABAcB] = true; // 38
        Recipients[0xbaD8DC9ba84207045FE8DF65F463746856Ec64F5] = true; // 39
        Recipients[0x1C465a0587D07C0548774457A63F20324CAAe918] = true; // 40
        Recipients[0xf2f45fF543290063348f55C39dDE7c05bF4669ED] = true; // 41
        Recipients[0xCfA8286b0383eF4d3C687Ab437b049Da8258511c] = true; // 42
        Recipients[0x61ECf13430925D295cD6A2d31255dA0CF877C5D5] = true; // 43
        Recipients[0x0761522433f81783CC59b37CA50c8bE22c9824f8] = true; // 44
        Recipients[0x3ef48Bb2DD7fF1391F8ad416cDe5b583C286D0E9] = true; // 45
        Recipients[0xE31066cf92D17d61F3E859f5D3E7677b52DC5369] = true; // 46
        Recipients[0x254483e74e0a6aa08EA95faD89e500377FF0F6e0] = true; // 47
        Recipients[0x0B7d05CAEee61Fe3b72b4580026b8871a394CfCe] = true; // 48
        Recipients[0xE1fFD408C1ab304Be75f7A9A788c13B56e82195E] = true; // 49
        Recipients[0x78C789784A08b76B1A8288A2E1e07997133b7f6b] = true; // 50
        Recipients[0x00D0bC7d15E5d397e4982A69dfB6b95363f4Ab8D] = true; // 51
        Recipients[0xD2243f37bc9E941D675D04d6617B2b257dB01eB6] = true; // 52
        Recipients[0xDE80508220a578b5905B20Dd5483466Fd6AD45e0] = true; // 53
        Recipients[0xa6C132C601FC127C535A5DdAb7cEF99Bc87d7BF7] = true; // 54
        Recipients[0x2890eDC10C6Ae42709C2921a50474E9A7C1D629E] = true; // 55
        Recipients[0xf18979d18870B97e368c5270782D63122d36471e] = true; // 56
        Recipients[0x5Ba59387147a16E590a8489Da94919BD67C7F5a5] = true; // 57
        Recipients[0xc48890aa9121b3715c02d65b67d0c2809c9827dc] = true; // 58
        Recipients[0x7F1889CaeF93f4Bc128CA10c08210749B56824FC] = true; // 59
        Recipients[0xBE288E652fF75418f8187Ac65FC93C941A2c2738] = true; // 60
        Recipients[0x13AFF39299DeDE30DE186FEdaD2D4684aCB2Fe7A] = true; // 61
        Recipients[0x362bcb47b6e3691551ec5a94924aeb991a12af1f] = true; // 62
        Recipients[0x0100620ed3462B04a35b030EE37AbdE3216509a9] = true; // 63
        Recipients[0x3b63e8a1faa43faada6d1949aec14ad4745b1df7] = true; // 64
        Recipients[0x34fDD1DFf26B75d16024D765D3011c2F7F38399d] = true; // 65
        Recipients[0xF93aC60a2f2bC178E93C4548B25ee72Bb46820c1] = true; // 66
        Recipients[0x8406bd0362CB53AbE54cDaac10FB57B883B83Eed] = true; // 67
        Recipients[0x80606Df893C39F8AF4Fa9CAc37b27bb2CE474D88] = true; // 68
        Recipients[0xF5bf895e0Cead8c94817955D2ab5F64932043329] = true; // 69
        Recipients[0xAD2BE9c4D1BB74dF20E5bBD3e22d869629e6a243] = true; // 70
        Recipients[0x82DE61e4Cb022e3A129f7be21559a9bFb635bF7a] = true; // 71
        Recipients[0x1E8a4540181361b826129129B8AD20c6F4cB722e] = true; // 72
        Recipients[0x28BDd06672073dA75BeC141108A5af1680dD6472] = true; // 73
        Recipients[0x20e9BbD862E3492C91d48DE856Ad1E9894c7349E] = true; // 74
        Recipients[0x88519E4bfd4b442b4F315462C4825FE6012a1344] = true; // 75
        Recipients[0x5bCd2BC57ba7b6b073c352fC75Da9b01BF1B9fB6] = true; // 76
        Recipients[0x8484d4EF874329CBE0eBccf9Cf715EAE3F6D488D] = true; // 77
        Recipients[0x94C819Ebc7e35f731a4F27fa39CED25235b621F9] = true; // 78
        Recipients[0x136ae1Bf326AdAf424Ab54C2Cf6dac70cd7402f5] = true; // 79
        Recipients[0x8e08E737f3Ae66F0Cc4473673de48D5Be09EB350] = true; // 80
        Recipients[0x0cCb61564Bc72A9666eB879Daf2c0e0DCdD61a6a] = true; // 81
        Recipients[0xEb45B0B072b3E8BeaDb2c70B428416Ae058B7360] = true; // 82
        Recipients[0x2b53a6CF1Cbda94f09d8EaBffD61858A3b864E3C] = true; // 83
        Recipients[0x3d0C127Bba41693BeD03153da25Bc16DE68454Ea] = true; // 84
        Recipients[0x0Bb842a74AFDB905CC2bb2c7531Ab2887D4e16ef] = true; // 85
        Recipients[0x713068d58B48bc3FB013C66A900243E84c44CC4E] = true; // 86
        Recipients[0xACE672184B87f57B3AF541ea5F1b3F5f3ea44BdA] = true; // 87
        Recipients[0x49Fa1B3cA78343DDba9a1E28a1d68D1910de5D51] = true; // 88
        Recipients[0x76D77a4BE0C9b3bb3024DB1AE2349128A85659C9] = true; // 89
        Recipients[0xb0ab986093356b87A366AFF72D34f68CF5aDabD3] = true; // 90
        Recipients[0xb5423fE2d33B241F641aa0db9Ce4529cfd91724B] = true; // 91
        Recipients[0xdDA875aB21eEFFEaE8DAfC5Ae3bFd21d9acE6d21] = true; // 92
        Recipients[0x2E07187dCc71a5F852C0B8793853e292F3c69828] = true; // 93
        Recipients[0xC98b32450A8AF1bd5b1b5D87a4975Fdc3a5f6041] = true; // 94
        Recipients[0x03e8E0be104b1F6a11D3103eBAFe3D585eC09b37] = true; // 95
        Recipients[0x67f6d0F49F43a48D5f5A75205AF95c72b5186d9f] = true; // 96
        Recipients[0x0e010120a3139412061ab2c1CbE34CbB1dF82bFb] = true; // 97
        Recipients[0x0C34eBF011f25F6b886738d8B5566e8B634fFFa1] = true; // 98
        Recipients[0xfAa99D427a2C4f55161efBaD534295d427E4a236] = true; // 99
        Recipients[0x6c1d36264bdf6Fc8F1922A2143b1cC987BEdB4C5] = true; // 100
        Recipients[0x116915477C938fe48eFB49cf1FF1c4c4C6eCFcc4] = true; // 101
        Recipients[0xAC099Fa76322D6A40Ab9E1849a58029EAc94B2f2] = true; // 102
        Recipients[0xd294Bab188e49A9151fC2A49D7AD389393C85745] = true; // 103
        Recipients[0xE176edfaf5b24df0aA00FBfd1B2d894BEA8d8B4B] = true; // 104
        Recipients[0xD949fc374D44762df32590C18E8730a3aDCCF016] = true; // 105
        Recipients[0x6BE1cbe1E426A1826F2ae232feA1855BC1638f6f] = true; // 106
        Recipients[0x770d4CB8418bf57fd7b48A8166adBf5D4aA2Ca20] = true; // 107
        Recipients[0x9F365022299d6D511124CD6fb6d87304Fd9cB58C] = true; // 108
        Recipients[0x5963764fD23ec5Ccc4723d4acFd7e0e02C1bAC94] = true; // 109
        Recipients[0x5e25FD421e6E154724bDbF1780E109d029F7f87d] = true; // 110
        Recipients[0x67a74297Ab50d3cA923B62eE76938C4a7E112c4E] = true; // 111
        Recipients[0xB52e05F7d3c03446Ae8Fc61b45012278d693E0eC] = true; // 112
        // 113 (Next Contract)
        Recipients[0x44E9Ff68B1E5f153eBDc1c0D999aB4AcCe378f68] = true; // 114
        Recipients[0x9Da3A610482a8dB9Eda850B6fF08F0aB39698506] = true; // 115
        Recipients[0xD1136Aa3788885E428CC5120c6db445fFeF8Ca6B] = true; // 116
        Recipients[0xf4a6d4C2f4688A1773178cF23080c24051f4DCcB] = true; // 117
        Recipients[0x1001C063E1a814AaCd5dc01928bd4d3dCdE0D0e4] = true; // 118
        Recipients[0xbAffc78825d5409B2CB49E542064B6C13C73C2Ec] = true; // 119
        Recipients[0x29899491bAba82f955b3638DF567FF97E33C2BCF] = true; // 120
        Recipients[0xc2Bba30aB90f1f27f6E47Fcd5de1F554AE079Fa1] = true; // 121
        Recipients[0x59cA2789D3137E08C3308bB3883c72ef53EF5814] = true; // 122
        Recipients[0x87CfE8a3FE4756ECC6171a7235CEa06880Ab231a] = true; // 123
        Recipients[0xd9d0b9f85c8df4ab48079d21f91ac761273a3f60] = true; // 124
        Recipients[0x51409fC86b9511B4251C8Cda387bE5310D3e9c91] = true; // 125
        Recipients[0xa222193237A64cF342412714812CC313051c4FD6] = true; // 126
        Recipients[0xB8efD0bB9cF02285fD3BE2fe0bB7D299378515f5] = true; // 127
        Recipients[0x7E1B754b29df2cf4F4ceB400d664fca1BC2C440f] = true; // 128
        Recipients[0x5f223347A9DF6228eCf903304451F38682B10c3F] = true; // 129
        Recipients[0x8cFA0060A2128bBe77Cc65295dE43580622DAfeA] = true; // 130
        Recipients[0x9b6Fe6aacd57d81919Dc72E08700aFDFF8EE6bC3] = true; // 131
        Recipients[0xB8410c4b10Cb3ec99ecA5521Bf0189cFd171fE5e] = true; // 132
    }

    function getAirdrop() public {
        if (!Wallets[msg.sender] && Recipients[msg.sender]) {
            token.transfer(msg.sender, 5000000000000000000);
            Wallets[msg.sender] = true;
        } else {
            revert("You have already received ;)");
        }
    }

    function backToOwner(uint256 amount) public {
        require(msg.sender == owner);
        token.transfer(owner, amount);
    }
}