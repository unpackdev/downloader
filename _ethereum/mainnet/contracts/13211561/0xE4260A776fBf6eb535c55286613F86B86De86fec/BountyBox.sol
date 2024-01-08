// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./Hex.sol";

contract BountyBox is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {

    bytes private constant cipher = hex"b4d3d4c6dbd32c20e7d0e020d5d0ead420d6d9c4dce5d9e1d3c520d5d5d420d5d7d3ded520dfd5e1e220dac720e3dcd420d4d0c4dfd4e82e20b7d0d3e620ebd4dacd20c5dcddd92e20aadf0adae4e7e320c3d020e1e1d9dcd3cfcfd0e2e2e0e820c6e3c4d6e3ddddd520dfd020e1d9d0d220dfc9d6e22e0a0aaadf20dbd4d9d3e120cccf20d0d8e5d3cfdfd6dfdee9e220d4dbcadfd8e820cfcfcf20dee4dde3d320ded0dad420e2d9cad7cde020e8de20c8d0d520d7d9e1d32e20b5d5d8e720dbd0d8c6dbe32c0ad4d0dd20dad42c20d7d420d5d5d420dcddd4df20d3d0e7d2d7cfccd5d6dddb3a20d8d3c6db2c20d0d4d5d0d320d020dbddd520d0d320d9d5d4d0ddd520d0e2d320d5d4cfd8d4e6d8dcc82c0ae1d7d920e4c6d4cd20d8e720dacad1d5d2d320d0dcc52c20e4d7d9e1d320dbd3d2e5dddee3d4d7da20dee2dbe720dac3e0d2e9e1d320cddae1d4e720d1d0e0cdd120d6d420c7dad6dbd32c0adcd0e220cedfe4d4cfd3de20ce20e1d4e1d4ccc8d220dddd20c220cdcedddbe4cfc8d020dcddd920d1c2d920e2ddd8d4e0d4dfc2dbd32e0a0aa2d7c2e02c20e3d6c620c8e2d0e6d3d7c2d920e4d8e0db20cfdad520e1d9e5d3c2d720d6e3e7d4dac720cbe2e2e820e7c6df2e20b0e720dbc6d9d5d6dee2d4d22c20d5d5d8e720d7d420d5d5d40ad5d7d3ded520deda20e2d8da20d0d8e4d7d3d3de20d5d8d8d3d3cf20d8d6e3dcd8dc2e20b5d5d420e2d3c4dacfd120e3ddd32c20dadce420e6d7cdd720d3d8e2d32c20d4d420d020d1d7d50acedce1d920d3cde0d4d6e5d920cfcfcf20dae8e7e3d3d3d4d0e2e22e20c7d0e020e4dee227e220d3c2e3d420dce3c4d320e0e4d7d2d3d4de20e4d8e8d720cecccfe620d7dedcd7d0cfe1d8e3ddcfcd0aced2e3dcded2d42c20e6d4e820d7d5de20e0dee0e4e2cadacf2c20e3ddd1c620d3d2e5d9d0dac6cf2c20e6dddbda20ded5dfd8dfd420dadad620d0e720d4c2d4d3d9e820e2d7cedbcdd22e20b0e10ad4d520d8e720e5cadfc920dcd5dde720dfc9d6dddbe220cad920d9d8dad43a20dacfd220e1e4e1d520d4d6dce4dbe720d6cfdce620e6d6c6ddc620e3e320dad0dacc2e0a0ab820d4d4cfd0d4e6d4dada20c9dcdfd920e5c620c4cedd20d2ddcfdfcadbe4d920e2c9d4d420d2e3dde4c6ddd4cee3dddedc2e20b2e2d8e8d420d4daced220e8d8dbc620ced6d6dce320d1ccd4e00ae9dde2cad720e4d420d7d3c2dd20d3e1e3dc20c6ccc4d520e3e3d6c6dd20ced6d5d8dc2e20b0d320d7dee3d3dec62c20e8d7d7d420c6dbe3dde1d3cde420d1d4e4d4dcc5de20dcdd20d7ddd80ac7cee2e820e7d0e020e4d8e0db20d4dacde3d420e3d6c620d4d2d2e3ddd220cecaddd7d9e12e20c2c620dcddd6d6d520c6e3d4e220dbc6d0d520d0dbd0d7cf20d2e2d8e8d420d4dad0db2e0a0ab720cfd020d7e3dfd320e4d0e220ebd8dacd20d4ddd4e2e320dadad6df20e8d8dbc620d8d2dbe020e3cfdfcad920e8d7d3cf2e20c0e3d5e820c9d0c2d9e3dce82c20d1d3d6d4e2d32e0a0ab4d6ddd7d4e0c6d7da2c0a40d3e0cadbc4dfdedae320262040c0d8e6c1ddd4d0d1d2dd0a000c010802d80061009b05e2017b010601a5005106b302e3026206d701fa007702cf0774020f027f0031083501c60299020b00b0002002120854002f030300b90425009501cc01d908bd005703bc022609b2028d048000540152044b02cc0a9709da025c04e20b2303a705e000810592036b03cd0c00032e0574085e0c4e00d900c2071503b7025b0c6300db047d062b0afe0f59062d01f900050f2d028300cb06e40fc301c900d4020002f906a3070e03f2109a00a306ad07140242111d00a4081103ad0487113509ae06f608fb08fd020a0007006400a6074d00660a2e114c114b00de00b60ade120200bf00f7035b047a116e12e1056a065e01780b2713260427068b073708a20b8e0a3d140f0ba50100097803f30c6e14b202650cfb150d051509680f6c119517c111a30df606c301500d6e0c2e187615b7078e18e40e760e070415060c1976083c15c40a560e82072e055c1abd00251cd00b4f08e5051313771dde0439096b02f603740b98135a01ac14181e17057a16fe17430bf51ebf048f1acd0a360d6103fd21d816820ca60cd7231619d80c79010b124c23b400c81e6112f413871d3b040d1ee524c5027b014b0eef0d70139624fa046f09dc02fb262c014e0fa227d804880c2b0c570d9e281a13d405bd015b09b902a61c26189c06f203f005c506230cc403f128b11da40ada228329310fb50d5704a6296505fa104c0dc504490e9f29860e7206080fc1233818a029c30f3f02dd29e41c340e4d2ace2b1605bf04d21ee918d50f5104ad21c111702ba7063921cd0d800df22bd81dcc098b2bb0000d2db0190c2de92c85059e193f2ce61e220e5f30402e0506101b670673075d22bb1e4c32732e790278366504d9303f22121154062f22291532376332ea064404f423101bcb114a073b235711e2335d0716236d112511283785247e059d069406fc05fe3a14270f016301d3003901d600b5011a01bd14d001d202250444004305c60504049f044f023402b6051b06813b2f054c04f63bd306923e1e03120779004703a805cb01b6275300be16e90584031f09ea0add0506043d08720065064e03cb07fd01140a83009901db07690b9a03d30afd28fa0a241898011c02050f4e05af075c0927072911ab05eb34bd07850b63124112da34e50c380c6c122219ce34e8196411f400d14044362640962a4c1535422e1f2d37ef12a1123c39482b7015c713a319bb3b7e08c430e61376140c45622b8a0a703b8a00ac15712be0169e3b9517c42d9404c13bce05e912cb0be83c0a0a793108137e3cac0ad1326417e719ba3ebf2f8f170345773f4a0b00143b179831231f7e32b70ba9315e0a0232e8194919e43f660767202617f30be51a3733761b4800e5404606a219000d9621f31a3947d51b1a0de8416631b4173749f642961a461a671c0708c74ac224d242e01a830e9a444934481ab21d101ae8448b0c4b1b4034a01eda21204b1a19c107b64d290a814596000f4e5c367719f645ae1c301a4445c20cd937ed27ff4f9c0f6d0e5c2370239e06c00abb0b5f0bfd00281c4945d00cda23d0397f1efe00fd463237e71b5a506c48f110351ca70e7f1a693b160ba2061149ac0bbd1d160e9749cd0e3039b21bea4a791c421fc72a4851c40e693e6224150bc84b0c203f1c583e90552d2c473b2d0eda3e9c4b600a5d204841241dca4b6b41f81ec755df4c4c0f3c1d831e46426f2cac3d770f4b46674d451e011f5e4e34003b498520f256cf2e521b3d103c3d8921df0b4b0c4d0272212d584d503c1bd51e23244e0a4b59fc503f0f830eeb238d136c4a5220511e5323cc52425ae000290c5a5ba114de4b661f28526c1f7824165f3353960f1543b02f43443d011260124f3a6146313805d153ee544c21fa63c355270af144cd26f028cf642756ef556145151c511f82317b64b72189223655ac20bc0f9b58325a0823086597587f273b217b29c20a93677b31bb0db300700c6622580f1f030f0cc759ec02ce2538205a2a2e5a5510141002242d15e45b132063233925175ba316b3461f25cd5be123cb280129fc0ce55be91301681c5dd6177947f62ae02bb968b7241460b9136a0ee960db5d68253968d6614a0a001026490132c224a9207f498729b40e4161ac001e4a1c02e068f461f22a8e120334e3698362f162c7251863ed2ab314c613f2011f208f65280eaf4c5f65f90d464f5a2bcc2d1769bf65b466b34ff524d325c5374a6a132abe2af966be257e2c052d58148d6771163525a1189567ac527138f46b57682c20962c396a54177b26082d3a66cd3c1f26542d636b1c26581077116c10a3111601342fdf18806cd36c2b1bdd27f618fa6c52296b52920c246dc46c931b61537b3025307b6ed626e86d84676329e073456dba10ec198930641bc26ed420e72b9c3072084b70c108b008ad717174a3716d2a5978cc418b71aa0d50210d330a369f71e61522796072732b177d72308476367543796a2be9766479af2ad1813677862dcb2c9238bc0cac81ff44572f4911fb545827282b514539836831c9327e12cc77e002d12d9c78e57b922b918c147a1e0cd121371ede7bbb2dbc45917ac70a262eac7af87da92c6592747cb332fd10d62f50257a3a2b342015a312ed133100277e0c0d52301345aa2bdd811930f610f5826c23ec54811a5d81c025a031ad30ba062082721f4032b11e3a8314013f2a400abd2d6082d083e2318b379c83b8848d1605948c8560854a2f8d955285b73ccb55ba36348c0f85f5383332a19a5286019701395c87a13661396c3d4f0d079aac8803970e30142b18366688fe45e32b5a2eb32f313e829af3161b894600013f209b2556ec38bb9d0814412ffb398c89ce33373c1498c18b8520e439fda05c8ba79de7319da21a8c980b3a2132580e46882ffe2f905b0936198cb50db75f103fab40a8a25a9edf8cd313d53c5d46f88f815fa339a2214c915a3d80a01d323ba2dc471691f210fc2177498b11c43e8f3b85a44792f8a02634ef61603af394b22f983cb2a074a6174a49636a240da69630833d250b5695030e8630dba7de352a950eaa5635dfa8e717cf24293f083dceac214b8d64372486afe69541b1e03f6e960125f240b1647e30f801489759275241b2228c4c3e987116684281240c4152b55b2891171a9954007c3e65998d2a774370247b99fa65875052a9239a8b664c0f2267605088aa060b249bc33390b651432e9bcf13025a2d361f0d376bb2b702abd79bdb0431ad192b559d463a8f43ba9d52027d2525450ab7a59dc343ee4295ae01180e5bb13b2a30b5324640ddaf0b9e356bec10346d822dc31c4b1865186701b0b1fa9e466fa85c08b9369f3b299c469c1932b937456c3d02bcad0de774431bec45a42fb0a040369377ff13c9149c3055a089320f47ac2b9ea0c347c1487a45c6162fbcb8328da1d9b7b73c5e3d2147df1d86a30f03093e4278d6be19a3fb7b014712a4377bb726713e5b3fdabcfd16d0bf4e0155c3504793bf9d033fa4ee0079c00aa5053fe34920a5c52f4f15b3a78fc086496f1878343b49ed3060a826106e3e7bc7f5c0f43f11c9ae5d36a93a347f49f83201a9ff10dc3fec476e49cfabbec11fc9e24ba94eedac2b4cd8c3473f2bcb575d6d49d3ad3640e74da610f8adc83b794ec0322eae1e33c53ff53480ae56401cc374af784efd5e6daff547d84f4ec37e1de718b31be80002506a1394b00b0b8f52acb05627a250ba801b40250156b11d13a641328047c46fb14f407a4a0eb4ae601840fe0d2642b1c61c151933f251ca54743c7eb6b83c8952be377861b14a4005541bff1c5500a9434c480c27b3cb6b6231cc3c57823e2b0b6a1d0f01893564632d44301916289363a5554b1658c7c5b712028bb98b02ca00ed4c776639019256504a8ecfef193ed1db49e21dbd";
    uint256 public constant price = 0.02 ether;
    uint256 public constant bounty = 50 ether;
    address public solver = address(0);
    address public constant guardian = 0x90E319D6cD7eE80Da3Fb30AB30C65A991c140F32;

    constructor() ERC721("BountyBox Token", "BBT") Ownable() {}

    function _maxTokens() private pure returns(uint) {
        return cipher.length;
    }

    function mint(address _to, uint _count) external payable nonReentrant {
        require(_count > 0, "at least one token must be minted");
        require(totalSupply() < _maxTokens(), "sale end");
        require(totalSupply() + _count <= _maxTokens(), "not enough tokens remaining");
        require(owner() == msg.sender || msg.value >= _count * price, "value below price");

        for (uint i = 0; i < _count; i++) {
            uint tokenId = totalSupply();
            _safeMint(_to, tokenId);
        }
    }

    function solve(address payable _solver) external nonReentrant {
        require(msg.sender == guardian, "can only be called by guardian");
        require(totalSupply() >= _maxTokens(), "not all tokens have been minted");
        require(!_isBountyClaimed(), "bounty has already been claimed");
        require(balanceOf(_solver) > 0, "solver has no tokens");

        solver = _solver;
        Address.sendValue(_solver, Math.min(address(this).balance, bounty));
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "insufficient funds");
        uint256 remainingIncome = (_maxTokens() - totalSupply()) * price;
        require(_isBountyClaimed() || (address(this).balance + remainingIncome) -_amount >= bounty, "bounty may not be withdrawn");
        Address.sendValue(payable(msg.sender), _amount);
    }

    function _isBountyClaimed() private view returns(bool) {
        return solver != address(0);
    }

    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        require(tokenId < _maxTokens(), "invalid token ID");

        string memory codeText = string(
            abi.encodePacked(
                '<text x="50%" y="50%" dy="40" fill="white" font-size="120" font-family="Helvetica,sans-serif" dominant-baseline="middle" text-anchor="middle">',
                Hex.encode(cipher[tokenId]),
                '</text>'
            )
        );

        bytes memory image = abi.encodePacked(
            '<svg width="1000" height="1000" viewBox="0 0 1000 1000" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#000" d="M0 0h1000v1000H0z"/>',
            codeText,
            '<path d="M322 241.5H677C722.011 241.5 758.5 277.989 758.5 323V678C758.5 723.011 722.011 759.5 677 759.5H322C276.989 759.5 240.5 723.011 240.5 678V323C240.5 277.989 276.989 241.5 322 241.5Z" stroke="url(#a)" stroke-width="15"/><defs><linearGradient id="a" x1="337" y1="294" x2="638" y2="706" gradientUnits="userSpaceOnUse"><stop stop-color="#5BB1FA"/><stop offset="0.20" stop-color="#FCB3EB"/><stop offset="0.35" stop-color="#DAE9C4"/><stop offset="0.54" stop-color="#08F8F9"/><stop offset="0.67" stop-color="#6C9BFF"/><stop offset="0.77" stop-color="#D470EB"/><stop offset="0.87" stop-color="#CB75EB"/><stop offset="1" stop-color="#1DDBE7"/></linearGradient></defs></svg>'
        );

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                                '{"name":"',
                                string(abi.encodePacked("BountyBox #", Strings.toString(tokenId))),
                                '", "description":"BountyBox is a collectible code-breaking challenge. Hidden within the tokens is a private key to the guardian wallet. Once all tokens have been sold, the first one uncovering it can withdraw 50 ether from the contract.", "image": "data:image/svg+xml;base64,',
                                Base64.encode(image),
                                '"}'
                        )
                    )
                )
            )
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
