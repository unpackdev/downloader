//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.5
//      fixed linter warnings
//      added requiere error messages
// 2022 OKIMS
//      ported to solidity 0.8
//      fixed linter warnings
//
pragma solidity ^0.8.0;

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verify(uint[] memory input, Proof memory proof, VerifyingKey memory vk) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }

    /** Wrap functions **/
    function verifyingKeyWrap() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(21071259873715856376892532351326985955863640256139477323685816556465131498970,3273661695701467877954268119558862257640854305837671988039160296991970096075);
        vk.beta2 = Pairing.G2Point([3223504183250904539284949703549163930280637245825868627408642641447756153521,13221169828338890541189312458857077471633507495480134746989210318304280189508], [18738805511941877336857987515147410706623310982120373378236801271098441113234,20598149861909938324894869133939251052805717779124470337507349969583533012540]);
        vk.gamma2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = Pairing.G2Point([4920240878778706820841130902574243098903266394774252550805550279643026003474,3299617659488799584474774884485745472048186748390932166821421594693419044839], [18848368008306462000510104552327927467410718620867577790506626778060528825771,5312129703469352474957005251286780794740828575398030447916922754765631898869]);
        vk.IC = new Pairing.G1Point[](4);
        vk.IC[0] = Pairing.G1Point(13221965337883509340394697230899267968507866162240026271879726677505496376719,7641884163210951230670216413730437480712414408920351337402344177997470321047);
        vk.IC[1] = Pairing.G1Point(1830785249331998147463042953387517918838644120280882826226431939649206805190,17289188016326843376351893353315270544559727703276733780687151704250085465562);
        vk.IC[2] = Pairing.G1Point(830068797406911030300066096605915632308077606371304055065161940478044325315,1573277313149946579646555400290051180011747227551511259222482577282418932099);
        vk.IC[3] = Pairing.G1Point(14982396171589090511646245306828545699664376946357198374546064777797878600660,19541308020423098744172843472786259187210897111539279695282921117509855584710);

    }

    function verifyProofWrap(bytes calldata proof, uint[3] memory inputs) public view returns (bool r) {
        // solidity does not support decoding uint[2][2] yet
        (uint[2] memory a, uint[2] memory b1, uint[2] memory b2, uint[2] memory c) = abi.decode(proof, (uint[2], uint[2], uint[2], uint[2]));
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b1[0], b1[1]], [b2[0], b2[1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](inputs.length);
        for(uint i = 0; i < inputs.length; i++){
            inputValues[i] = inputs[i];
        }
        if (verify(inputValues, proof, verifyingKeyWrap()) == 0) {
            return true;
        } else {
            return false;
        }
    }

    /** Unwrap functions **/
    function verifyingKeyUnwrap() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(21071259873715856376892532351326985955863640256139477323685816556465131498970,3273661695701467877954268119558862257640854305837671988039160296991970096075);
        vk.beta2 = Pairing.G2Point([3223504183250904539284949703549163930280637245825868627408642641447756153521,13221169828338890541189312458857077471633507495480134746989210318304280189508], [18738805511941877336857987515147410706623310982120373378236801271098441113234,20598149861909938324894869133939251052805717779124470337507349969583533012540]);
        vk.gamma2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = Pairing.G2Point([12250977273742417332274834264497108635810335853344451137462676587841905769296,11155301207363330271695088160520628590836843254492447850675555676589888663522], [20611911634538266610355446746927805406410601790268880448726433823896779724550,15815854370830818666923820344296317250375533315485552821529233225668516433859]);
        vk.IC = new Pairing.G1Point[](7);
        vk.IC[0] = Pairing.G1Point(16857803598635102319944568934400324637021620625576414016694516886276464000973,11965030814132190762133260314016470724831377031069011941359114581914839344561);
        vk.IC[1] = Pairing.G1Point(10004909327864165619827597834224903835253282880215312379805915661284754604905,20028689015031584086307297901815351105965181932218131684664579321907024573811);
        vk.IC[2] = Pairing.G1Point(20792261499405473219689564325214021702324987967797380859875376188470715182873,11589306309580500977048036262033638661340801879283385024125977109048717846015);
        vk.IC[3] = Pairing.G1Point(21042171226098824410115321517693112509021633193363122963311335184088340390479,6004654054749041600696100807982176703902396233478645930049222103066227607593);
        vk.IC[4] = Pairing.G1Point(11601309097087966608221056546990666766783941533949561614965295736521837708289,3453555569791257414072797898396788511647207344470711397937012395353740198809);
        vk.IC[5] = Pairing.G1Point(17337405664075668981687055600945147208565816718395316558729212347987475104002,11585593897586883585169700721221019267634617447974874346854266569601373044695);
        vk.IC[6] = Pairing.G1Point(13889234684656230128464493141079939841777181656555129727524266839490939128680,14189174584239616783510895973732353899673031108151867781090465988621838570574);
    }

    function verifyProofUnwrap(bytes calldata proof, uint[6] memory inputs) public view returns (bool r) {
        // solidity does not support decoding uint[2][2] yet
        (uint[2] memory a, uint[2] memory b1, uint[2] memory b2, uint[2] memory c) = abi.decode(proof, (uint[2], uint[2], uint[2], uint[2]));
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b1[0], b1[1]], [b2[0], b2[1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](inputs.length);
        for(uint i = 0; i < inputs.length; i++){
            inputValues[i] = inputs[i];
        }
        if (verify(inputValues, proof, verifyingKeyUnwrap()) == 0) {
            return true;
        } else {
            return false;
        }
    }

    /** InitTransfer functions **/
    function verifyingKeyInitTransfer() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(21071259873715856376892532351326985955863640256139477323685816556465131498970,3273661695701467877954268119558862257640854305837671988039160296991970096075);
        vk.beta2 = Pairing.G2Point([3223504183250904539284949703549163930280637245825868627408642641447756153521,13221169828338890541189312458857077471633507495480134746989210318304280189508], [18738805511941877336857987515147410706623310982120373378236801271098441113234,20598149861909938324894869133939251052805717779124470337507349969583533012540]);
        vk.gamma2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = Pairing.G2Point([15719856381092672674924886587647347393941419486752744257693267106749002471594,18305312584003134224640915652645557115075406672236373318603118076307984548046], [1408775682445274465121581188121634134215560554590300689511200293236218368887,1498307666346124435882353509419111127647833167912699504681226210270236499663]);
        vk.IC = new Pairing.G1Point[](4);
        vk.IC[0] = Pairing.G1Point(20070097278647040148398142690142892355965269249609510188278747096360792327047,10632768930032945901790108225035692020993564375880606192190852738652392597936);
        vk.IC[1] = Pairing.G1Point(12841909676507916352328177437074260007456679767225648836193246547286281807331,7562561349942504570717691139329627734758219697484718130697281849233551276458);
        vk.IC[2] = Pairing.G1Point(17675584613823650419386289821706822445750063906104667860473884979682736491310,19757270201670747177857469615539297993926674958491882992431296753805097341613);
        vk.IC[3] = Pairing.G1Point(17193783567410328981619030691365995836691737172437167033005443448495363990174,15107921707423139597182166292456094275971200496646705401659533160110200675053);
    }
    function verifyProofInitTransfer(bytes calldata proof, uint[3] memory inputs) public view returns (bool r) {
        // solidity does not support decoding uint[2][2] yet
        (uint[2] memory a, uint[2] memory b1, uint[2] memory b2, uint[2] memory c) = abi.decode(proof, (uint[2], uint[2], uint[2], uint[2]));
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b1[0], b1[1]], [b2[0], b2[1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](inputs.length);
        for(uint i = 0; i < inputs.length; i++){
            inputValues[i] = inputs[i];
        }
        if (verify(inputValues, proof, verifyingKeyInitTransfer()) == 0) {
            return true;
        } else {
            return false;
        }
    }

    /* Complete transfer */
    function verifyingKeyCompleteTransafer() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(21071259873715856376892532351326985955863640256139477323685816556465131498970,3273661695701467877954268119558862257640854305837671988039160296991970096075);
        vk.beta2 = Pairing.G2Point([3223504183250904539284949703549163930280637245825868627408642641447756153521,13221169828338890541189312458857077471633507495480134746989210318304280189508], [18738805511941877336857987515147410706623310982120373378236801271098441113234,20598149861909938324894869133939251052805717779124470337507349969583533012540]);
        vk.gamma2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = Pairing.G2Point([125763765175806517938357771708336235356487475344441687857353360545144334037,20929944331282002688160906159989025115337910769217410503271412936368611478714], [19561716960022911275201576419327459460348236354516643442706082665839879910309,3022743040386578978880219471708938918298840532436765761568695130013172417323]);
        vk.IC = new Pairing.G1Point[](8);
        vk.IC[0] = Pairing.G1Point(11215831293967356420838079803284577602389099599623135426510603912188245769928,4837401527122104979507268333954218209231526895458927630607010030325720001244);
        vk.IC[1] = Pairing.G1Point(4661307061470556742032373196552775551745664044272076046044990405855617706945,9824787875849885537401471761183168665284494235191813050413122095838640568208);
        vk.IC[2] = Pairing.G1Point(15516137399211215531946011744315481640223338376187421840010499721172367020527,16075646083265040508825775738167207031797114798924065821497659574262286900765);
        vk.IC[3] = Pairing.G1Point(7762196946990360463003777741956810244400772235980882003309862935885807321831,4466951542857385534907682985645457178200345871131466165224733990490443085935);
        vk.IC[4] = Pairing.G1Point(1153790545622250014587154605972719494937193583680984266675835009399614643070,795584468127754759357335308862105565989633603270773759684021538273334312294);
        vk.IC[5] = Pairing.G1Point(19538616801657829660276765049272915914397082419230197452974911061744452561169,4369192434742331805995374307838722752603947129101732309575754638357232153512);
        vk.IC[6] = Pairing.G1Point(10981972160316952439658658660740922740197407839937887390109322390121039254819,12107520456514805349194649117721864066107666679430101797622533644372812026022);
        vk.IC[7] = Pairing.G1Point(17457780582189098888200096742028096010157132112671708943560227177462311007246,9738639805840220319051802986567922944332063287466938020765605173603023632997);
    }

    function verifyProofCompleteTransfer(bytes calldata proof, uint[7] memory inputs) public view returns (bool r) {
        // solidity does not support decoding uint[2][2] yet
        (uint[2] memory a, uint[2] memory b1, uint[2] memory b2, uint[2] memory c) = abi.decode(proof, (uint[2], uint[2], uint[2], uint[2]));

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b1[0], b1[1]], [b2[0], b2[1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](inputs.length);
        for(uint i = 0; i < inputs.length; i++){
            inputValues[i] = inputs[i];
        }
        if (verify(inputValues, proof, verifyingKeyCompleteTransafer()) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
