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

    const mainApp_PProfile = "1ec76793-4a05-45c8-a7a0-3531f4e632de";
    const uiExtn_PProfile = "8c08d73f-a987-4a27-a3b5-d5a66438fb02";
    const nonuiExtn_PProfile = "ec69590b-15f4-4014-85e8-4cab1f4b94ea";

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


