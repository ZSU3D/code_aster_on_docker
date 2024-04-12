# Build aster code docker image
docker build -f "code_aster\Dockerfile" -t aster_zs_code:latest "code_aster"

# Run aster code docker
docker run -ti --rm -v D:/Code_Aster_docker:/home/aster/shared -w /home/aster/shared aster_zs_code