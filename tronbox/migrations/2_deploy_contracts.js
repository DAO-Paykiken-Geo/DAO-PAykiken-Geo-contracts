// var MyContract = artifacts.require("./MyContract.sol");

const PaykikArtifacts = artifacts.require("Paykik");
const UsdtArtifacts = artifacts.require("UsdtTest");
const HoldArtifacts = artifacts.require("Hold");
const GovernorArtifacts = artifacts.require("Governor");
const SwapArtifacts = artifacts.require("Swap");
const TeamArtifacts = artifacts.require("Team");

let paykikAddr, usdtAddr, holdAddr, governorAddr, swapAddr, teamAddr;

async function Deploy(deployer, artifact) {
    // deployer.deploy(PaykikTest);
    await deployer.deploy(artifact, { gas: 2000000 });
    const myContractInstance = await artifact.deployed();

    return myContractInstance.address
}
async function HoldDeploy(deployer) {
    // Hold.sol / Hold / constructor(address pA) - paykik address

    await deployer.deploy(HoldArtifacts, paykikAddr, governorAddr, { gas: 2000000 });
    const myContractInstance = await HoldArtifacts.deployed();

    return myContractInstance
}
async function GovernorDeploy(deployer) {
    // Governor.sol / Governor / constructor(address usdtErc20Addr, address paykikErc20Addr)

    await deployer.deploy(GovernorArtifacts, usdtAddr, paykikAddr, { gas: 2000000 });
    const myContractInstance = await GovernorArtifacts.deployed();

    return myContractInstance
}
async function GovernorSetAddresses(deployer, governorInstance) {
    //function setAddresses(
    //         address _swapAddr,
    //         address _holdAddr,
    //         address _teamAddr
    //     )

    const res = await governorInstance.setAddresses(swapAddr, holdAddr, teamAddr)
    console.log("GOVERNOR SET ADDRESSES RESULT:")
    console.log(res)


}
async function SwapDeploy(deployer) {
    // Swap.sol / Swap / constructor(address uT, address pT, address gA) - usdtAddr, paykikAddr, governorAddr
    await deployer.deploy(SwapArtifacts, usdtAddr, paykikAddr, governorAddr, teamAddr, { gas: 2000000 });
    const myContractInstance = await SwapArtifacts.deployed();

    return myContractInstance
}
async function TeamDeploy(deployer) {
    // Team.sol / Team / constructor(
    //         address pT,
    //         address[20] memory teamAddresses // address firstAddr, // address secondAddr, // address thirdAddr, // address fourthAddr, // address fifthAddr, // address sixthAddr, // address seventhAddr, // address eighthAddr, // address ninthAddr, // address tenthAddr, // address eleventhAddr, // address twelfthAddr, // address thirteenthAddr, // address fourteenthAddr, // address fifteenthAddr, // address sixteenthAddr, // address seventeenthAddr, // address eighteenthAddr, // address nineteenthAddr, // address twentiethAddr
    //     ) - paykikAddr, addr1, addr2, addr3, ... addr20

    const teamAddresses = [
        'TB378zxPrdmorNhHnr8f4Xdff3BvQB92ac', // 1
        'TFv49vEukXy6YwWX1yW6Rmx4uB6Bosk6cA', // 2
        'TMTqpUxceKc7raNPnHfR8kGVpsbJBMsAAc', // 3
        'TGCzvsB7widG5D4j1BAbRKYAZZXnYyDwY6', // 4
        'TNjp8YdLvX9vuokzHvrKTjcSdoaUGU88BN', // 5
        'TDsPwYXVVyF2Y78ssAW9Zq58ky8o5pDFgh', // 6
        'TXS1LPa8WzQVwnjxvDTcMaFMpw5KwAiXie', // 7
        'TLyPJYHfxygNYQi94wnTFFTbo3hmzwzMWq', // 8
        'TSi3zvXqYvBPAEYdAsUyHfxobFGRKrMcPp', // 9
        'TQAJxRSDqsMPXJ3Xva3D8EJmRCuBWVAdBU', // 10
        'TU8pcDxzJEQRb8XSMRPApRXpJMnc8ugtt2', // 11
        'TY3UjGnGgJgTYwKB26VLWnC8qkih7VsUPi', // 12
        'TF1FyxtSBKb4sBanXtxUzF8fj3VmZK1evg', // 13
        'TDmRGLYYUaQ6Hv6g14kEN2TsNPJk4APKSX', // 14
        'THJtT9sVHbCEFau4paUimKs5Bc6RkGaDKi', // 15
        'TFakwCr6AUw92DEA1eqC4UgFb9ebbsskVc', // 16
        'TLZ1fnuV2Tm1mq8wiWe5MY7pzjVrryZ6Cx', // 17
        'TNC2JTAR4vgaiRLi52yY52C32zLegaBmPb', // 18
        'TTVecMbqDUeagf8uEvAsPX1MJb4GtNZAEu', // 19
        'TLVgUtfwj9XagKkt2YZ976qPpa9GKmBmhT', // 20
        'TDFiUPh8TApsqzFToUKzLLq1BUAPXs26MN', // 21
        'TLotMZYVZak9owbQUjRNmmd9NZ8eVezLzo', // 22
        'TLjfhCuPdhm4UncXWyFi34wDjiXFExVAfV', // 23
        'TGuXLqcQEi1KnJyGb11C4swGc7bwdYxVGM', // 24
        'TRTucaAPai5pbDBXHWurYmdqnPXJVAHC9f', // 25
        'TDHuqmhiQtAvE2PY2zfZYvd4mXfiGKrsZv', // 26
        'TNbiCCovUxiiG8TQEuJhuyRjUmSZgjun6Q', // 27
        'TUdwrGVbJB6TdACtifPnNCDoeyh3m1pyG7', // 28
        'TKDaY5G27fB5Y4UykhkeAsP3HdVWUq63vF', // 29
        'TTUkJjzR9DkC2Q1L5GCcbxAgnj8WcxQpNg', // 30
        'TKXVnuXwDAas9T8CPKTFiWu81diHGUUUxu', // 31
        'TM9PADAmJWeffFCTtCZT2DovpdCYA38DED', // 32
    ]

    await deployer.deploy(TeamArtifacts, paykikAddr, teamAddresses, { gas: 2000000 });
    const myContractInstance = await TeamArtifacts.deployed();

    return myContractInstance
}

module.exports = async function(deployer) {

    paykikAddr = await Deploy(deployer, PaykikArtifacts)
    // usdtAddr = await Deploy(deployer, UsdtArtifacts)

    // paykikAddr = "TQcqC2nx27sRmLSzBwgFr3ZawTK4iTtFNq"
    usdtAddr = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"

    const governor = await GovernorDeploy(deployer)
    governorAddr = governor.address
    const hold = await HoldDeploy(deployer)
    holdAddr = hold.address
    const team = await TeamDeploy(deployer)
    teamAddr = team.address
    const swap = await SwapDeploy(deployer)
    swapAddr = swap.address
    await team.SetSwap(swapAddr)

    await GovernorSetAddresses(deployer, governor)

    console.log("Address list:")
    console.log("Governor:", governorAddr)
    console.log("Hold:", holdAddr)
    console.log("Swap:", swapAddr)
    console.log("Team:", teamAddr)
};

// module.exports = async function(deployer) {
//     // todo remove tests
//
//     // paykikAddr = await Deploy(deployer, PaykikArtifacts)
//     // usdtAddr = await Deploy(deployer, UsdtArtifacts)
//
//     paykikAddr = "TQcqC2nx27sRmLSzBwgFr3ZawTK4iTtFNq"
//     usdtAddr = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
//
//     // const governor = await GovernorDeploy(deployer)
//     // governorAddr = governor.address
//     // const hold = await HoldDeploy(deployer)
//     // holdAddr = hold.address
//     // const team = await TeamDeploy(deployer)
//     // teamAddr = team.address
//     const swap = await SwapDeploy(deployer)
//     swapAddr = swap.address
//     // await team.SetSwap(swapAddr)
//
//     const buy = await swap.calculateRemainderPrice(179912312300000, 153412800, true);
//     const sell = await swap.calculateRemainderPrice(179912312300000, 153412800, false);
//     console.log("Buy", parseInt(buy._hex, 16) / 1e8)
//     console.log("Sell", parseInt(sell._hex, 16) / 1e8)
//
//     // await GovernorSetAddresses(deployer, governor)
//     //
//     // console.log("Address list:")
//     // console.log("Governor:", governorAddr)
//     // console.log("Hold:", holdAddr)
//     // console.log("Swap:", swapAddr)
//     // console.log("Team:", teamAddr)
// };