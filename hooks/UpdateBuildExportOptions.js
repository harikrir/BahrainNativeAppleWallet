const fs = require('fs');
const path = require('path');

module.exports = function (context) {
    const projectRoot = context.opts.projectRoot;
    const buildJsPath = path.join(projectRoot, 'node_modules', 'cordova-ios', 'lib', 'build.js');

    console.log(`📝 Project Root: ${projectRoot}`);
    console.log(`📝 Path to build.js: ${buildJsPath}`);

    const mainAppBundleID = "com.aub.mobilebanking.uat.bh";
    const uiExtnBundleID = "com.aub.mobilebanking.uat.bh.WUI";
    const nonuiExtnBundleID = "com.aub.mobilebanking.uat.bh.WNonUI";

    const mainApp_PProfile = "b0246b74-0b0b-4bc5-acee-a6bc24fc5e61";
    const uiExtn_PProfile = "aa49cfca-de68-4606-ac06-ba9171b553a3";
    const nonuiExtn_PProfile = "39271141-1795-4f2a-866d-3e37a49735c9";

    console.log(`📝 mainAppBundleID: ${mainAppBundleID}, mainApp_PProfile: ${mainApp_PProfile}`);
    console.log(`📝 uiExtnBundleID: ${uiExtnBundleID}, uiExtn_PProfile: ${uiExtn_PProfile}`);
    console.log(`📝 nonuiExtnBundleID: ${nonuiExtnBundleID}, nonuiExtn_PProfile: ${nonuiExtn_PProfile}`);

    // Read the build.js file
    fs.readFile(buildJsPath, 'utf8', (err, buildJsContent) => {
        if (err) {
            console.error(`🪲 Error reading build.js: ${err.message}`);
            return;
        }

        console.log('📝 Successfully read build.js content.');

        // Define the new provisioningProfiles block for three targets
        const newProvisioningProfileBlock = `
            exportOptions.provisioningProfiles = {
                "${mainAppBundleID}": "${mainApp_PProfile}",
                "${uiExtnBundleID}": "${uiExtn_PProfile}",
                "${nonuiExtnBundleID}": "${nonuiExtn_PProfile}"
            };
            exportOptions.signingStyle = 'manual';`;

        // String to remove (the entire block you mentioned)
        const oldProvisioningBlock = `
            if (buildOpts.provisioningProfile && bundleIdentifier) {
                if (typeof buildOpts.provisioningProfile === 'string') {
                    exportOptions.provisioningProfiles = { [bundleIdentifier]: String(buildOpts.provisioningProfile) };
                } else {
                    events.emit('log', 'Setting multiple provisioning profiles for signing');
                    exportOptions.provisioningProfiles = buildOpts.provisioningProfile;
                }
                exportOptions.signingStyle = 'manual';
            }`;

        // Replace the old provisioning profile block with the new one
        const modifiedBuildJsContent = buildJsContent.replace(oldProvisioningBlock, newProvisioningProfileBlock);

        // Write the updated build.js back to disk
        fs.writeFile(buildJsPath, modifiedBuildJsContent, 'utf8', (err) => {
            if (err) {
                console.error(`🪲 Error writing modified build.js: ${err.message}`);
                return;
            }

            console.log('📝 Successfully updated build.js with new provisioning profiles.');
        });
    });
};


