// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IL00kinToken.sol";

/* L00kin Token | $L00K
                                      .:;^<|iii|*r;~>.
                                .;LyDQQQQQQQQQQQQQQBB#dmz+,
                            '=yNQQQQQ&BQQQQQQQQQQQQQQB#NNN#NX\~
                         ~cqQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#NN&DJ_
                      ~Y%QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBNN#Di.
                   .|bBQ@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBNN#j,
                 `iDBQ@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#N#x`
                ^qNQ@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#NR;
              'agBQ@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQNBy`
             ;KWQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ##q'
            <R8QB#QQQQQQQQQQQQQQQQN6jxztjk%QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ&N%,
           =%WQB#QQQQQQQQQQQQQQ#S=~rISESn*~;YgQQQQQQQQQQQQQQNKXUK%BQQQQQQQQB#%'
          ;%gQQNQQQQQQQQQQQQQBa~!6@@@@@@@@@Wi,igQQQQQQQQQWu!rYEXS7^\KQQQQQQQ&#d`
         'd%&QNBQQQQQQQQQQQQ8*,6@@@@@@@@@@@@@Q+:XQQQQQQQo,*Q@@@@@@@D!<%QQQQQQ#Bj
         I%8Q&#QQQQQQQQQQQQN=:N@@@@@@@@@@@@@@@@T,XQQQQQ{'t@@@@@@@@@@@z~DQQQQQQNQ~
        ,%g&QNQQQQQQQQQQQQQv'R@@@@@@@@@@@@@@@@@@\,DQQQZ'i@@@@@@@@@@@@@}~&QQQQQ&&E
        v%gQB#QQQQQQQQQQQQK'z@QSi!~~;*j8@@@@@@@@@~*QQB~,Q@&qk68@@@@@@@@+jQQQQQQNQ,
        E%8Q#&QQQQQQQQQQQQz'U|'..rnou>'.;D@@@@@@@5'DQK.ij~.,!;',7Q@@@@@D;QQQQQQ#Q|
       `DgNQNBQQQQQQQQQQQQ^',...D@@@@@Q,..f@@@@@@B.yQf.~..z@@@@t.,%@@@@@'dQQQQQ&Bj
       '%g#QNBQQQQQQQQQQQQ;''...j@@@@@R,..'Q@@@@@@,JQz.~..I@@@@o..^@@@@@:kQQQQQB&h
       .R%NQNBQQQQQQQQQQQQ!''....,^|<~.....%@@@@@Q'sQu.~...,=<~...;@@@@@,kQQQQQB#k
        6gNQ#&QQQQQQQQQQQQi''.............r@@@@@@%.mQX._.........'m@@@@@'DQQQQQ&&y
        ugWQB#QQQQQQQQQQQQk'~,...........<Q@@@@@@x,gQ#,,;.......,w@@@@@q!QQQQQQ#Q\
        ;ggBQNQQQQQQQQQQQQB<,WZr'.....~zN@@@@@@@Q'zQQQz.j&5\?Lnd@@@@@@@;mQQQQQQNQ~
         Eg8Q&&QQQQQQQQQQQQR~!Q@@QQBQ@@@@@@@@@@Q;!NQQQ#='q@@@@@@@@@@@@|+QQQQQQB#6
         ;%gBQNQQQQQQQQQQQQQK~^Q@@@@@@@@@@@@@@Q;;RQQQQQ8>,E@@@@@@@@@Q>rWQQQQQQNQ^
          7%WQB#QQQQQQQQQQQQQ%*,y@@@@@@@@@@@@f,LNQQQQQQQBo~^6Q@@@@%7;yBQQQQQQ#&m
          `a%NQ&#QQQQQQQQQQQQQBE!~zD@@@@@QD7:^UQQQQQQQQQQQNmi+<Li?7k#QQQQQQQBNg'
           `a%NQ#&QQQQQQQQQQQQQQQD}*;~;;~;?j%QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBNN~
            `n%NQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ&N8~
              |R8Q@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#NR:
               ,mgBQ@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQNBZ`
                 !KNQ@@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#N%!
                  `LD#Q@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#NBj`
                    `^mNQ@QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBNNNu'
                       ,iqQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBNN#D\.
                          'rj%QQQQQQQQQQQQQQQQQQQQQQQQQQQQ&NN8Bd7,
                              .!zqQQQQQQB#&BQQQQQB&#NNNNN#&qn^.
                                  `,=7aKNQQQQQQQQQQ#Rqoz<~`
                                           `..'..`
*/

contract L00kinToken is ERC20, Ownable, IL00kinToken {
    uint256 private immutable _maxSupply;

    constructor(uint256 cappedSupply) ERC20("L00kin Token", "L00K") {
        _maxSupply = cappedSupply;
    }

    function mint(address receiver, uint256 amount) external override onlyOwner returns (bool status) {
        if (totalSupply() + amount <= _maxSupply) {
            _mint(receiver, amount);
            return true;
        }
        return false;
    }

    function maxSupply() external view override returns (uint256) {
        return _maxSupply;
    }
}