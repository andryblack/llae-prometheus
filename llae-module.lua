name = 'llae-prometheus'

dependencies = {
	'llae',
}

function install() 
    install_scripts_dir(dir .. '/scripts/prometheus')
end
