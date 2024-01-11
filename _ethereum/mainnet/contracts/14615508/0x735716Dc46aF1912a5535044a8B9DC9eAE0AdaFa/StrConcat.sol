pragma solidity 0.7.6;

library StrConcat {

    function strConcat(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory ret = new string(ba.length + bb.length + 1);
        bytes memory bret = bytes(ret);

        uint k = 0;
        for (uint i = 0; i < ba.length; i++) {
            bret[k++] = ba[i];
        }
        bret[k++] = byte('-');
        for (uint i = 0; i < bb.length; i++) {
            bret[k++] = bb[i];
        }

        return string(bret);
    }

    function strConcat2(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory ret = new string(ba.length + bb.length);
        bytes memory bret = bytes(ret);

        uint k = 0;
        for (uint i = 0; i < ba.length; i++) {
            bret[k++] = ba[i];
        }
        for (uint i = 0; i < bb.length; i++) {
            bret[k++] = bb[i];
        }

        return string(bret);
    }
}
