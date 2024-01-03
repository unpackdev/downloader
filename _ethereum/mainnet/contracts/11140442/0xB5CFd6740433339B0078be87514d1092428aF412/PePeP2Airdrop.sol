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
        Recipients[0x8d478d1ef31297956545688F03bb78ea40bcB05F] = true; // 133
        Recipients[0xa1c2C4d9E29495FF629541ee67B0696FDE3DddE6] = true; // 134
        Recipients[0x765E4506047F0bA8573d67595cD36B77b7a882d2] = true; // 135
        Recipients[0x3289c62092890f412aCaEEc7bDDF2e02c8617Cd5] = true; // 136
        Recipients[0x2B02572Ef413D800351A1aDE24576a5416E72C28] = true; // 137
        Recipients[0xde0e2e95EE5d36834F452E0298aC98b92c8f1b61] = true; // 138
        Recipients[0xF2DF8BF993A9787861fe0d1a91c47FDa8f40672c] = true; // 139
        Recipients[0xe43C85ca13aCA2D5f297fc8f35d8256332c1eaB3] = true; // 140
        Recipients[0x0dB8d77470407833E881E09368a29aB595d6a31E] = true; // 141
        Recipients[0x838AA80A3f80CfdDAC1249C5D84e283739A9c454] = true; // 142
        Recipients[0xAaaD9B757E3698445Ae3Cc5Df362dff8DB72f217] = true; // 143
        Recipients[0x46e829199eC7AFe21384620406bCf1C381209AFA] = true; // 144
        Recipients[0x8615d8dfcD7f0978c617fB64782dccfCc78df52e] = true; // 145
        Recipients[0xbbeaA0B1887f483225416e70B95E33Cf4F9653f8] = true; // 146
        Recipients[0x33a6d59475C69725e1621d3C5CbAB85d6CC9BD85] = true; // 147
        Recipients[0x7D18B321856b4347E29c82a33e6468dFd5504CD9] = true; // 148
        Recipients[0x9fCa89329d5D8cCBD402C628F4B68Fd8747d6BAD] = true; // 149
        Recipients[0x3aa30Da50f064b1108c6E52BCfB418A7f293fDad] = true; // 150
        Recipients[0x28091c2c5a957194255131836a007535A4e27220] = true; // 151
        Recipients[0x75e61B3934dBb11a17b9241Bf461695960095054] = true; // 152
        Recipients[0x4eAa8dB1A3019c3E0AEb0B523466d722B4801feC] = true; // 153
        Recipients[0x11E087dd5bC68Fce0E7d3F1dffb477f238887892] = true; // 154
        Recipients[0xed4C0b34b4AE9B45c077CFF8A5E0542Aed5C8aa9] = true; // 155
        Recipients[0xF9ebca9539d93E7afA9d169a98dB1982B10B9B2E] = true; // 156
        Recipients[0x745f36D8C3780bD4E015A5e04F7f940590306e4A] = true; // 157
        Recipients[0xe7CcB501174dC9F09821a38358c9375cc3c76a25] = true; // 158
        Recipients[0xc68FA83DD174B21F60407fe488683C7FCcFdD044] = true; // 159
        Recipients[0xb86ce826A28692931c60Fb03d9c259369a5777D6] = true; // 160
        Recipients[0x7508e3328B477a4Df886E423d5730bb19d76020a] = true; // 161
        Recipients[0x413499A5C18c16dADf1a2b1A253795645B1b5dE9] = true; // 162
        Recipients[0x42214996Ba51769507c899388d818a9949926D8e] = true; // 163
        Recipients[0xeDe71D58Eb92c4Eb065d2709a08970f789e7084b] = true; // 164
        Recipients[0x3E97740ECE8a293fc467d1F8D22aFdCf629cB34C] = true; // 165
        Recipients[0x6916B71FB3b0fAAe2E86EBeD0852d298a7fCaFa6] = true; // 166
        Recipients[0x354e56bF03cC7bB0E29A00F3D08495795FaFE71F] = true; // 167
        Recipients[0xb33d8ccD048f1ac4F60C7C9142C8ac7EF57f5b16] = true; // 168
        Recipients[0xA3f6681b523723230909583BD1f713c1da93E9e9] = true; // 169
        Recipients[0xAe60CB6FcDB9a0b787d9819c9e0af75cF0A9b500] = true; // 170
        Recipients[0x9e602c1920443F01Cb100a57A7F894df8Eb42f66] = true; // 171
        Recipients[0xF9f52fDD24AEa31e0b9e7959ff13422F405f46C6] = true; // 172
        Recipients[0xca49E8de951CD814F38a8f50a775751f17F74340] = true; // 173
        Recipients[0xAC02a7d3A8E48d29fe2a47AC57b495e58e17cd5A] = true; // 174
        Recipients[0x65DeCa9E81C1Bbcc1DBc548A2f16BfcbEa967C96] = true; // 175
        Recipients[0xeA718dF698A8622187A2920BE599396c93f76667] = true; // 176
        Recipients[0xc0a3fc33D046860b59E61f4Fa65B18Af31e1433a] = true; // 177
        Recipients[0x14b9ab7C219461fb631A91E4E0980B625AbD0A48] = true; // 178
        Recipients[0x0cE4206f1d44489369a4e86859231940Cf492C45] = true; // 179
        Recipients[0xE62ea5Ec96d974Ca67a198Df537fb1bc081420Ef] = true; // 180
        Recipients[0x5B20f3c1221f5824bf39ff35BcE0E5FB441B7d44] = true; // 181
        Recipients[0x55dB0FfFEf0aD96554e81bd18C1243Ad7e3f9098] = true; // 182
        Recipients[0xFbf7a67991D41Ff0378430F73A41A6d56960CF09] = true; // 183
        Recipients[0x4B8507E91eb33DA1c6847aBf9204844941B5F4eD] = true; // 184
        Recipients[0xdeB4B4e0821f64BEa463EB4ae28A58978277AFB7] = true; // 185
        Recipients[0xA87C3e41b2fA772e43006C92DB1A1014775e4825] = true; // 186
        Recipients[0xEE10E7143DB2Ed31b1622a108Af5366704D2B1BE] = true; // 187
        Recipients[0x6717617F757214F9AFd874fd5527A4bb9e9aBc5d] = true; // 188
        Recipients[0x43f4fd480383E514AdC6667CbD590dE420734373] = true; // 189
        Recipients[0x43f4fd480383E514AdC6667CbD590dE420734373] = true; // 190
        Recipients[0x897011b8c785be3344ca2b8F8aA513386dc29671] = true; // 191
        Recipients[0x13Bf68626dccBF66759b470aa6Ae0CE8387bc206] = true; // 192
        Recipients[0x4F8BF7BFF7030453CeabA3104aD49Df2B6CB628E] = true; // 193
        Recipients[0xE65Ed02e4bcdF4D91CB7bcAda884972aa609726A] = true; // 194
        Recipients[0x512dC4cA0bF4EC6d85D26FA2FA80fdddbe7C5d0a] = true; // 195
        Recipients[0x9d409EbF8604C8F1D91873971924fD874F02c142] = true; // 196
        Recipients[0x65EF6100e5561f3585E920c2E373f356eBeF7587] = true; // 197
        Recipients[0xC8acFb60693D948f9e846e37458A27A24B7Ac5e6] = true; // 198
        Recipients[0x47BF1b80276bB2c67F01F182d1FAD41bd95b7Dd6] = true; // 199
        Recipients[0x6a6126B6a18A094e8C669665Fa16f282cf190bC5] = true; // 200
        Recipients[0x60CD7c31823B8eC099d6cb6F2b32b03ef72665Ab] = true; // 201
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