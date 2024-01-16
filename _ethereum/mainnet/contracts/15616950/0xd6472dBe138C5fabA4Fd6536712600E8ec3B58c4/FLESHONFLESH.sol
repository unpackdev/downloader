
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLESH ON FLESH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    uvJYuJjsusJsJs1JJJ1susuJuJuJuJjJuJuJuJjJ25KXKXPPdPPKKXPPbdEPPEQQMgDEDEgdbK5JuJjsuJjJXEuKLLjJuJusjsjjuJuJjJjssY2IjjUu11IuUUUUUj12UY    //
//    YvvYYYLYLsLJYssJsJsusjJjJujuJjjjJusuJuJjYU1IUIIKKPX5UKKqr2ZbU```vREZD5::J5juJujuJuJJsgKq1vYjYsYjsujuJjJuJjYY1KSJYsYJYjsJsjYJsJJuLv    //
//    YrYYssJYsJjsjsjJjJujjjjsjJjjuJjjuJuJjJusu155SSKKPPb2IK5````jX7-``JQM:````r2uuJjJjJJsY1QQBuLvJgjsjJjJuJusJvL2gM2vjJuj1uUuUu11112u2s    //
//    sLYJYJsjJjsujJJujuJuJjJuJuJuJuJuJujuJujusU252KKPKPKKIK``````:2j-`-BE````i7UUjusjssLsvJZBQBS77B1ssusjJuYY7uKMggK5juJ1uUuUj1u1j1J1uj    //
//    LvjYjJuJuJuJusuJusjJuJuJuJjJusjJujuJuJuJjjU2S5KSS221Kv``````-:Ki-`bi```Jj`2j1JjjqPUsIsdQQQBbLRR7YsjJsLL7XQBMQQE2jjuu1j1u1u1u1jU11s    //
//    sYJ1JuJuJuJusuJjJjJjJuJjjjJujuJjJjsujuJuJ1j21I1UJJsI1`````:``iLI:`````rdUru1juJubBQdEbPMRQQBQQRKvLLYvj5RBBERQP2sJ1u1j1JUjuuUuUj1js    //
//    uv1J1jjJ1j1JujuJuJuJuJjJusjjuJjJjJuJusjsjsUU55XSXIIX-``:--````:7L:-``-XIUuujuJjsYvXQQZdgMgQRQQRMR1v1dgBQQDEQQ2Ysjjuu1jUu1j1u1uuuUY    //
//    usu1juu1j1JuJusjJuJuJuJusuJjJjJujjjuJuJusju22XSX5SUr```v2r`````:r:```sK5uUu1jujjY2PDgBEgDMgMgQQBQQDRQQZQgbRBMjL1j1j1uUjUj1uUj1u1uJ    //
//    UYUjuu1juj1j1juJusuJuJususjsjsJJuJuJuJuJusuUXSqXXXd:-`jPEdPs:``:````idX5S5SI5II11JjXbQQEDgQggMQRQQBQQgQM2dMQXvsJuJuJUJUjUj11Uu1u2s    //
//    1JuUuUjuuujuJ1JuJujuJjsjsJYYvLLYLJsusjsuJUU5K57sPRS-Y55qu1UqP7iM7```IPr-:r75UvvU1uJ2MRQQgMQQMRMQQQRRgQgKgQMgKjYYLsYJJ1J1sjjU1UuU1J    //
//    2s2uU1UuUJ1j1jujujusJssLLL1ISSSjYvYYJsjJ11IJ:```````i--jUJ1Jui`dPi:-KU``````````rJs1gMQMRMQRRQRDZDMgRgDMBQZMbLJ1KI2qUjjs252uU11jUs    //
//    Uj1UuUu1u111uuj1JussvvuqXRQBBBBBRE1LvssjjI:`:J1ji````::JUuj2rv7vY7:iqbKXI7```rSYYj1gEggRgQgRMQMMdDgQgMgQMRggbZDBBBgPJIPDZPuuj1Juuj    //
//    Is21U1UuUu1j1JujusLvKMBQRMQMQMQQBBBQbYLY1u-`rXMREI-``SvJIjUI:```:-:UXIXXZX```dE2usZEKUUPMRQgQMQMQRQMQMRgRMQDMbDEMgZdQBBMZIJuUJuuUJ    //
//    UuU21UuUuUu1jujuLLXQQQRgEMMQMQDgRBMBBBSLJs-:vIggXD5:SP:uq52b7```:ii5SKSXqS``-X1uY5b2jU2KPDRBQQRQMRMRRQgMgQQRgDEgbQQBDESUj1uUu1u2Uj    //
//    2j2U2u2u111u1J1LYZBMgQQgMMMgMRMZRRQQQQBSLs```sDBBBBBI```5qbS:`-ir:-```-:rY``-I2JJKXISSX2jLjPQQBQQMRMQMMgQMMDRRQggZbuv7vvssjj11I12Y    //
//    2122121UuUjUjuYuMBgQRQgQQQRQRRRQMRgQMRQBI25:```7j:``-`````````rYrLs7:-``:L```U1J1KKqqPXS5v--LEQBQQQQRQMQQQbDMMMQQRPqKPqXUUuuu5S2uu    //
//    SjIu21U12uUu1jLbBgRRQMQMQQQRQRQMRgQRQMRQBDPuY-`````:2Iu:::i:7UIiXdgdPqqsrSL``JujXKPKSIIIb27-`-5dgBBQQQQQQqPEQEKgBBBBBBBBBBQPu--j2Y    //
//    21UIU21U12u1u1sbQQRQMRMQMRQQMQgQMQRQMQMQQBPjKPJ::jbBJUjXSPPbqS7-KPqPXKUU`2EPU1s5SqKX21s17Li2U--7YdPgBBQgKsZQMRdEEEKS12U2uIUIUJv1Uj    //
//    Ij21212121UuUjXgBRQQQRQMDgQRRgQMQMRRQMQRQQBPKMBi`-YgBSS2qS5IqXS2bqPKqXS2:s1j1s2PEKPuvv:ir-`:Pb````-7U1uKP5bEDdDPJvYLsYJJuJjjUUI12s    //
//    IU252IU212jUuJbERBRMgBQQDgMQMQQBBBQMRBQQMQQQbBBI`7DMB5uqKPXqKEPXqdqPXK5SU2sJYJXKPZUq7i-`-```-`-XSj``````Y5IXKMgsLju2uUu2J112UUU2Uj    //
//    SjIUIUIuI121u1gEgQQZXQBQQgQQBBBRPPDXdMBRQMQRRRBBgQBBQQP5q5qKbPdqXPdqP5S21Yvvv1PjPBKdBj`````````:Jj`7r:````iSEPBSj1U121UU21U121212s    //
//    51U2U2UIU2U2JXEBZEbMrLQBBBBBQZ1JLJj2IggQQQMQRRRQBBQQRBBK2XqbPEbEKKbPKK21JIXDEKPUvBQu:SI```````````````````idPuS5jUuUU2uUuU121Uu21u    //
//    Su522UIUUUUjUKKZBMQBZ`7dQQPrv7r7USdDBDXEQRRMQgRQQgMRQMQIJuKKPbEdd5PPP51qQQBBDSbj`iDZvSBX:-```````````````-bKuJuu11U121U1U1212u2u2L    //
//    IUII2I222I1U155qQRQQYr---iirvsJPZgBBZI2dBQRQRQgQRQggDMQPJ2SPbEbEbqSbK5PBQQQBZKI7```iKBBQr-``````````````7gX11112U21IUI12UU1211JUus    //
//    S1I25UIU2U212uX1BQQQJ7v77rr7U2gBBbDXsu5PBQQRQMRgRRQgRMBd25PPZEDZgbSqqPBQQRQQQXv```vPRQQ```gQXgdi``````iSb5212U2U2U21U12U2121Iujj2L    //
//    IUI525I5UI1I1221RBQBBBMBQBQ5rubRg5jsv2IEQQMQMQQQZMQQMQQEUqXPPZZgdPI5KMBBQRgQBP`sgBBBRQ-```bBQI-QBi``-12QSuu21U1IU22U1I121UU2U2uujs    //
//    SUS2I2IU5U212uUKBRQMQBZ7XSbD::5SqIujU1SQBMQMMgQRgMQQBQBdIXX2UIqqdddISYXMBQBBBQjZDDDgM``````7Zqsv-``uBBK-EDjJ212U2UI12U2U21211uUjjv    //
//    525525I52I2IU1uMQQMRRQBK:irsJisPKEUsuUPBQRgMRMgQDgKbEQBMUUdRPXqbPZEbYiYbQBBBL`PgP5qP````5E```````:1gBRBI:vQKsUU22I22I51I121UJ1jjJL    //
//    S1SIS5525IIU2u2gBRQMRRBBgvr7u77UK5IKbSQBQRQZQMMgQQgIjvjEQKBBBDPdEPPgSruSZv````BbuS5s`````D`````:MB`2BgQBdsBZbu22I252I12U21211sjJjv    //
//    XI5SIS2S2525UUudBQMMMQRQBBMPYrr11dQMKqMBRQQdgMDMgQBQgEIuZBBgQBbddEPBBQsjK````:BB27--```:7Y-`rSQBBB7BMMMQQB1dQDJ2II252I12U2u1uJJJLv    //
//    K2X55I5IS25IIUuUMQRMMMQRQQBBBQdSKPq2LYQBQQQDggRgggRQQDgu7EBPMDZPbPbQBBQbg````ZBQBQdvvI2vYYKQBBBQB2QBgMRRQDPEQQZj5IS2I2UU2juj1JjjJr    //
//    5I5K5XISISU525u1PBQQgRMQRQMQQBBBbUUPsIMMQQQRMQMMMQEDMQdP`:QREBgDqPPRdBduXK```BBQRBBQZZgMZQBBBBQR`:MRDBRMgRMMgQQduS5512u11jJuJjssLr    //
//    KUK5X5XI5IS2IU2jPQQQQMQgQRRMQQQgREQBJ-MIBQQMRgRREDQgQgBg1`uQEMgZP5gBvSMggE``DBBRMRQQBBBBQBBQQMdKiMbgQQgEQgQDEEQQbUSIIU2JuJuJJYYvYr    //
//    XSSX5X5SIS2555UUKQgBMQRRRQMRRQQPME:i``2UQQRQgRDQgMMQQRgBQJ:DdggEEqgBSUBBQB``MBQBMQgMMQQBQBRgdRDdDKSQRQEMQgZggbgQd5II2Ujuj1sJLYYsJ7    //
//    qIXXXSKSX5XIS2I1UEQMZRQRQRQQQQQEdj`````rbDBMQMggQQRgQQbEBBusQMQPPPRQBYvBBBrsQPqRBMQRQQBgDbEEgQBgSvbQBgEgBgEgQEDDb25UUJjJjssLLvY7Jr    //
//    KXSKSKSS5SIXI522UdMBdQQQMRMQRQRXrr:-````UQQRMQMQMQQggBQgsQQKBPBBMQQBBZ``BBuJgE1gZRRMMBMEPEggRQggQEPQQgEQQZZBZEEMKI21JsYsLsLsvYLYYr    //
//    qIqXX5XSK5XSS5XUUPBQRMQRQgRRQQQJ7PBQBM``DBQQQRRRRMBDuMBRDsQBQPZDEMRQBB2`EBLjQ51PgIXqMgPdEDMgQMZDRMgMQPgBMXQQPdQDKI2uJvYvv7vvvvv77i    //
//    KSSqSKSKXKXKSX55U5RBZgRQRQRQQQZbrgBBBB``BBQQgQRQgDgBPuQRgdrRg27uvIrdQBBBB2rPg1bM5KZBREdgEgZQREZggMgBEXQBXbBbPRBduS1jvYr7rr777vv77i    //
//    P5KXKXKSK5XXXSXISJPBDEQMQMQMQQZK2rXBu``iEBMQSSRgMQbqB7`RMBriPdgqjjBQRRQBQs1D5vUKXQg2KbZDEZQQZdggggQZSEBZqQZPMB:`PUJYL77rrr7rr7v77i    //
//    XSKKXKXKXKSKXK5XI2IBKJPMQQMQMQgqXJ7`````rEBBgrdQdBBXDI``QBP`gZrLvbgBQQgB2qQgvUBKPddKdEDgERQgPggggMgPqBQEZQggRZ``PUv7rrrrrr77rrr77i    //
//    qIPXKKqSKXKXKXK5XI2gP11dQQRRQZdbZ1U2````-QggB2vdKQB7vB1``-r`IBI1vXMBQgQD2JMD12KIEKsIgZgEMMMPEgMggEDdMBZMBQEMdK2517r::riirr7rrir7v:    //
//    KXXPKPXqXqSKSKSKSX2PKSI2gBRRQR2gIu2EP```dSLZBBDP1BdrsRB1`````BBBBL`2QBMdERQMPb`7u1PgdZggMRddDMZREbgDMMDQEZQBuP21viir:ir7rrrrr7r7vi    //
//    q5qKKKqKqSqXqSKSX5XSK2SvKBQRQBMEDrv1Ij`dP``-KQBK`B`uQEDQBDP:sBBgMXrXMBbddQQDgP25LDBgEDgQBgggQQQDZMRdgDMbdQP-``SJ7iiirirrrrv777rrL:    //
//    XXqqKKXKKqKqSKXKSKSKS5IKdBQQMQQXI``:7:sMurr77QBQ`QrXEdbQM7``BBE2vL7rPBKMDDqgPqQXbQBZZMRBQBBBBQdgbQgdZQggQI```:Xvii:rrriiirr777ir7i    //
//    P5PKqKKXqKqXK5KXKSXSK5S5PZQQQDPEdJ:`-YKY::i-`i`````PBMb7```XBBQggPK2gS5BgZPbDMMbiiQbDQB``Li-``IgMMgRBBBQq7MEUKsr7iri7rririrr7r7r7:    //
//    KSKqKKXPXqXqSK5KSXSKSX5I2PbgQM1PQMPS11uu`````````sBBP7`````5dBQQggQBB5EBEDEqJ2ZgsKgEMBKib````MBQERRQMZbgBB`XqUv7v7r7r7vir7r7rv777i    //
//    qIKXKXKXKXXSXIX5XSXS5IX222dbDMquI1KSX5Iqb-`````PBBX``````:-IsQQMgDRMBXPBQEDSuXUSZBgDBR``s-``SBI7PMDDgbMBBDSEPqqSK1JUUIKjUUU1522Iqs    //
//    KSSKXPXKSKXKSK55ISI52X552USZdZdXIv7Y71gBBBBBBBB2-`````````BBsZBBQQQBQbPZQBMQdgEUPQdMgDIBBBBBr`7BBQMRMMZR2````````-````````````````    //
//    P5qXKSqSKSK5SSX552S2IISU52uKgdbqqsr1PSEQRDZdK-`````````````QQIXgQMMbdPZqKQBQb2ESMggDMQBBBBBBsEBBBQQRRDQ5``````````````````````````    //
//    PKXXS52XIXISIIUI2IU12SSSI52JPgEbSX7Sg:```:`````````````````2qDS2IdqPPEbEKbQQMdKPQDDQBBQBbqDiMBBQMMgEEEQ2``````:-``````````````````    //
//    21bXKSXSXSX5SI52SIS52jsuXJu1vSEEbPXjKr`````````Y5Kr``````BdJsJKgPuu2PEEdgZMQQQBBQZgP``````:YBQQggggbbKQb:```RBBB-`````````````````    //
//    uLMBQQQQgMgMZgggEZqZX7``Pu7D7SqbbZbqUPr``````-P2-```````QEqUJ22XKP2UKDgQQDgRMgqQQEZI`5Y`IDBBQBQgEgdZdPgRgDEQgggdPBBBBBBBBBBBBBBBBB    //
//    gs`RBQBRRgRgMZgZDZZdMgMYsbKEZPqXKPREEEMRPi``1MQBBBU``-KBBKKS5SPXKbBQBQgDZMQMQDqqgEggMBBBQBBQQggdZbdbDZIUbdEgMXEQQDZKPPQRggRRQRQQQR    //
//    J2r2qEMBBQQDDMMgdZdZdggP2gZDPPKP5bPEKPbgMBQEDgEEQBBBBBBBBdSPKPqPPEQQPbbQMQQQbddEPDKbdZZDPdgMZgddPbdK5EbS2dZPdMEQQgPbX2UdPPPbPPPbbE    //
//    qEgK121jUSX7SjbBQggZgZgEZZEEEddPvSDbbPEEEdd2PPEPRQZBgQQQQqPPPPbPdPgMQQQQQRRRP2KIqqPKPEZbEPPqbbdqbPgdU`````iZqdPPgDdQQ2sXqSX2XXqqEP    //
//    bBs`7-``1SKq5sJBBBBBBBBBBBQQgMDZEdPDEZEZdgq2KPbEgBMQQQMQQdPdqbPbPdPdZDbZDMgRQP5PPMqSXDEEddPPqdPqqPEg```````bBg5IJXgRQP722XSX5PPbKK    //
//    `r``diDdgQgDBZU```I```u`:ZPKQBBBBBRZEPbPPdbUqqggDDMgggRQQPEdZbdbPPdbEbEZgZRQBZ5UX1JL5ZZdEEgDZqbPPPQU````````LQKbK:UMbb-:LJ225SX111    //
//    `v:-BQKKPKXPPK```````````````````LdQBBBBEEqUXbgMDPPqPZbDgEbEZEPdPEPEZMZgDRQBQgEZDXuSXQBBBBBBBBDZggB:```-``````gB-``IBM7```-L7rYuJ1    //
//    :2BSKdjj7bE-5u`````````````````````````-qdbSKbRRBREPZEdDQDZEZbEdEPPPgQBBBBBBBBBBBsrrvPgDgq2bMBggBBBB:`````````b````5BBQ-``````-ir:    //
//    LPKDXPQdMBj`MK````````````````-`````````uQbdgQBBBEgDqbERggDgggEddEPPZBBBBB2i:i-```-````````````````ZB`````````1```-PBBB2``````````    //
//    vvBBdQD2bKr7QK````````````:PZBg``:`````7BBBB:BBv```ZQ5XbPjdPPbKqbgKj51Ps```````````-:`````````````````````````iSvrP2E2````````````    //
//    b5QBgP:EUr:gQR```-E``````7QDSZQMbd-````BB:`r``P`````BgbRSvv1r1sv7Uvriv1PPi``7``````:`````````````````RE:`````r5RP``ju`````````````    //
//    BMQMEK-IMi`jMQX2BBQbZ``````````1KJ:``2BBP``E````````rBDRQEDqjSX21rijd7SDQQ``-i`-r```````````````````b`2``-``PbQBj``:``````````````    //
//    gMBEDZgBB``gPb`````:u-```````````-```BBBB````````````iBdMEERdgQq``:5I7qXKB-``--````````````````````````Ej``KRBBK-````````:::--````    //
//    QBESBUrBB``KBg``````s-``````````````BBY`````````````BQQgPPbBQZRP``iKJrUbgMgs2QM5JDI````:````````````BB``B7rBRdK:`````````:iiri:```    //
//    DBb5BEKZI```RB``i```-``````````````5BBE```````````j-`BddPMZBQRZgMD5BBBbDBBQBQQQBBMdRBB2P```````````KR```-BKgK`QR:`````````-irrii-`    //
//    MQg5QQXDq```2g`````````````````````IBB`````````````QqjBSEDQQRRBBBBBBBDgQPY77JUKdP2SDRBB71``:MP`````````d`USvBvRBK```i`-:-:ri--i7r`    //
//    QBBRZgdBBq`````````````````````````QBP````````````uRBEDdbgBBDBBBBBBBQBBBDQdj7Y77r7vY1EBXr```-DP`iERQi``gqK-`D1II```--`--:r7Yvr:-i-    //
//    IgBBQRZZBd````````````````````````UEBg````````````BBQBbqbggQRgBBBBBBBQBBqqdbU`vsLsjsY72RBK```:Mr:rMQ``5qDEP-srI``r`v``-7qii:11I7--    //
//    :rMBBBgMQBi``````````````````````QB``````````````BBBZQQqbgRR:``:qQBB:````````I1juUj:`-`-vM```````````````7qUvjPg```7```d5:i`7UUP1J    //
//    SrrMBBBQQBBB1```````````````````QBBBRgBBg55UusdBBDMQBgMgRQBd-:LL````````````5Uvr:v7iPd2YjUq```````````````-2S2:Er7`:``:q:-r`-jIE5s    //
//    BBJrZBBBQMPBBBq````````````````BBBBBBBBBBBBBBBQgPdEgEQggRgBgbBP````````````Z7PZIIPv-XSjUUXE:`````````````r``Pq`Ki`````ri`-r-`s2gIu    //
//    BBBBqbBBBEQXQQ:QBggr``````````MBQI7r:7X2IgRMQDEPbPDEdRBgQBBQM````````````````qgEQLrPDPKSSXMB````````````ui``qPiU:`````:L--r:`-ED5s    //
//    ```````sqd5--``MBqIQR7``uBBg:-`````rs````bBBJMgZEdPDDRQBQBB-`````````````````rDEb2rMQQqi``:sE````-:```:BQPE``P5v:v``:``-``ir`igq2u    //
//    `````````````````````:BBBQBBb```BBBdXBBMq-:Ms`QMZbZZggQBBB``````````````B`````:SKI2S`rv```:-rv``--``UBBBZUsisrP`jB``vv`i`-vr`SB52j    //
//    u```````````-``````7QBBK```BB7`D`-Xi````````Bq`7dDgMQQMBB``-``--``-i``PBQ```````1KDI2bi:Bg`7PDZESIJPBBBBBZXEr`LL`X1````v175U`BRSjj    //
//    qjr:ii7LUIPPqj2U21PBBI``````BB2P```Y````````sBrgZgKBBBBBB-rd`IB```:``QBgD```````PgBQM2i``DMr```XBggjUEBBZvLX``vbr`R`````````-BgXSJ    //
//    PSUJJ12X5K515PPb2XdBK````````BB2d```J```gir7EBdMgIbZqBBBBBdqjQd1Bb````BBS-```````rbESQBQ-````````vBQ5MBBQIBBP`:BDPb`````````2BP52J    //
//    Su1JUU5555uY1UIKujBBBPs``-```jBBug-LBP:gMdgEBQMQQgZr-vBBBBBBPu2DB```````-```````:7rvjui```````````:`:r2Iv`ILJ7`1i```````````QDUI2Y    //
//    Uju5SSSKSKIS5KSPJsDgQBBi-Br```EBB:``XBjBjJBBUDBQdgEbr:1YQBBBBZ:-Sr``:dbu`i``:``PZRQBbE2````:``````````````````````````i---`1BDPZKI    //
//    gDQRBQBBBQBBBBBQKvBBQBBK`Qr````:BB```1q`BQBQ1IBBSPgbPd7`7QBBBBB5UI2jBBBD:`````vgBBBPI:JXRDJJr--i-``````````````````r-`rKv`:BBEPPbY    //
//    QBQQQQMRMQMQRQgRPsXggQBB2`27````7BB```jBBBBBBZv:qur2BQXbgMPMgQBBBgKZEQQqv`jqr`IBBdXbDv```rgQBBBBBBQu:1b5`````r-EQRUPIi--LsQBgSYu2j    //
//    RgMgMgMDggMgMgMgRPPbdPDQB1rZgB-```BB`````:gBBi``RdqMQgMgbJiXBZQQBKdBBBBBBBBQBBBdg--KP-:7ivbbQgBBBBBBR15E:jBBBBQQBBBQQgZEQBBQBgI7r7    //
//    MggggggMgMgMgMgMPPbEEEbdgB1`:i`r2MBg`````-JBI``QBBQRdPZZ5usJDDgRB2XBQBQQRQgDgXPPQE7-iKd`````````````dBgirddKKbqqqdEDDQRQgMDggQBQ2:    //
//    MgMggDMgggggggggDbbPbPqPbMBI``PBBB1iX```BBq```IBQgDDggMZdDBMMBBRBjqBQMQRRMDdI7qJqbP5rubD`````````````rQ2bPPPdPbPPPEdgZMggDgZggMQBM    //
//    gggMgMgMgggMgMgMgRMgDgDdPDQBBBBBD7sbsrJQBqPS``BBEgQBBBBBBBgQgEBBBjPBMQMMgDbPU7::iKiQBRRB`````````````iXPPPPEbEbEdEEZDgDgZgZgDMgMMR    //
//    gDMgMgMDZZgdZgDDgggDggRgRgMQBBZr:2v:BBBBQD2`sBBBBQEUs7ri``````5BBPgQQRQgRddbKUr:rLI:QMQQBL`````````2BQZbPPdPdPEbZdZZgDggggMDgDMgMg    //
//    gggggMggggPEZMdggggZEEDgggMQX7r1dr`7JiKUi:`UBBQQQB5-```````````:PRBBMRgMMEqdd5U:i7vv7QDMQBQ``````gBBgZddPEbDEEEDbDEgDgDMgRgMgMgMgM    //
//    MDMgMgggMdZgMgMgMgMgMggDggQ1:L5S5:```7S7```BBQRMQQBBX---727``````ruBBQQgREPXPbI2-rvii7BMMgBB27``BBgZZPddEbdZDEgEZZggggMgMgMMMgRgMg    //
//    gRgMggZMgMMMgMgMggZMZgPEgQBj7uIP2ur-:1J-``XBQRMQMQQBBQK115Ksi-```-irSBBBQREPSPbS2-vLiisBQBBBBBE`BgZDbEbdPEPEZgZMgMMRMMgggggMgMMRgR    //
//    BMREZDgDMDMggZggDDMggZEZQBBv2Pbuvii```:2BBBMMMRMQMRRBBBZv7juIjir```-``SBBQQEbPDEKXivvrivEbgBEIg`SQZEgDMZEZggMgQMQQQMQQQRQRQRQQQgRM    //
//    PJUdQMggDgggggDMZDZggQQBBRr7SZ5::``-jQBBBBQQMRgRgMgggRQBQXrJLivSj-``````dBBBBBBBBRgUK1J11```KBBR`BMMZMggbDgQMRggDggRMQRQRQRQQBQQQQ    //
//    YrJQQgMggDMgggMDMZDZMRBBP-i22:```7gBBBQMRMMgRMRgMgMgMgMgBBBd7```--`J:````:BBBdbDBBQQdQjSE```:``i`7BZMRQMMgRgRggggMQMQRQMQMQQQQRQQR    //
//    v-rBMMggZgDEDMDDZgZgQBBJ-7Sj````7BBBQBMMgMgggRgRgRgRgRgMgQBBQ1```````````r````````````E``````````7dgDgBBBBBBQMgQQBBBBBBBBBBBBBBBBQ    //
//    J`-EBgMgMggDMgMEMDgQBDr`JXq-```uBBBQQPERQMRgRgMMRgRgMMgRQMRQBBBJ````````B```-DP```````b```````````BBBBQ`ZBBBBBBBRMBQRQBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBB2:iuXP:```DBBBBBgZQBBBBBBBSRQQQQQBQQQBRQRBBBB5````````5BQdrv-`````bs```````````srQ``````iEX2L````````-77L``-rg    //
//    PXZbPPbPdEgDMDggQQQurv2XKr``-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQi`````-Lu1````:```Qv:`jbDDP27```````````````i2KXgDqI1JUr``````    //
//    `````````````````-7LsIUui`````````````````````````--`````-````:rvK5j7SJX:````````:L:-P:`KdX55X7```````````````-`:2Yi:riii-`PBQi`:-    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FLESHONFLESH is ERC721Creator {
    constructor() ERC721Creator("FLESH ON FLESH", "FLESHONFLESH") {}
}
